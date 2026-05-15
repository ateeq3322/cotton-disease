// lib/services/disease_detection_service.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — On-device TFLite inference + background heatmap
// Fixes: interpreter lifecycle, isolate tensor build, no setState
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ── Result model ─────────────────────────────────────────────
class DetectionResult {
  final String diseaseKey;
  final String displayName;
  final double confidence;
  final String severity;
  final String severityUrdu;
  final String treatment;
  final String treatmentUrdu;
  final bool isHealthy;
  List<List<double>> heatmapData;

  DetectionResult({
    required this.diseaseKey,
    required this.displayName,
    required this.confidence,
    required this.severity,
    required this.severityUrdu,
    required this.treatment,
    required this.treatmentUrdu,
    required this.isHealthy,
    this.heatmapData = const [],
  });
}

// ── Disease info ──────────────────────────────────────────────
class _DiseaseInfo {
  final String displayName;
  final String treatment;
  final String treatmentUrdu;
  final bool isHealthy;

  const _DiseaseInfo({
    required this.displayName,
    required this.treatment,
    required this.treatmentUrdu,
    this.isHealthy = false,
  });
}

// ── Isolate message for tensor building ───────────────────────
class _TensorMessage {
  final SendPort sendPort;
  final Uint8List imageBytes;
  const _TensorMessage(this.sendPort, this.imageBytes);
}

// ── Top-level isolate entry (must be top-level, not static) ──
void _buildTensorIsolate(_TensorMessage msg) {
  try {
    final image = img.decodeImage(msg.imageBytes);
    if (image == null) {
      msg.sendPort.send(null);
      return;
    }
    final resized = img.copyResize(image, width: 224, height: 224);

    // Build flat Float32List instead of nested lists — avoids GC pressure
    final tensor = Float32List(1 * 224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        tensor[idx++] = pixel.r / 255.0;
        tensor[idx++] = pixel.g / 255.0;
        tensor[idx++] = pixel.b / 255.0;
      }
    }
    msg.sendPort.send(tensor);
  } catch (e) {
    msg.sendPort.send(null);
  }
}

// ── Main service ──────────────────────────────────────────────
class DiseaseDetectionService {
  // Singleton interpreter — never recreated, never double-closed
  static Interpreter? _interpreter;
  static Map<int, String> _labels = {};
  static bool _initialized = false;
  static bool _initializing = false;

  // Heatmap cancellation token
  static bool _heatmapCancelled = false;

  static const Map<String, _DiseaseInfo> _diseaseDb = {
    'diseased cotton leaf': _DiseaseInfo(
      displayName: 'Diseased Cotton Leaf',
      treatment:
      'Inspect closely to identify specific disease. Remove heavily infected leaves. '
          'Apply broad-spectrum fungicide (e.g., chlorothalonil). '
          'Improve field drainage and air circulation.',
      treatmentUrdu:
      'بیماری کی قسم معلوم کریں۔ بری طرح متاثر پتے ہٹائیں۔ '
          'فنگی سائیڈ (کلوروتھالونیل) لگائیں۔ کھیت کی نکاسی بہتر کریں۔',
    ),
    'diseased cotton plant': _DiseaseInfo(
      displayName: 'Diseased Cotton Plant',
      treatment:
      'Immediate action required. Isolate affected plants to prevent spread. '
          'Apply systemic fungicide or bactericide depending on disease type. '
          'Contact local agricultural extension office for diagnosis.',
      treatmentUrdu:
      'فوری کارروائی ضروری ہے۔ متاثرہ پودوں کو الگ کریں۔ '
          'سیسٹیمک فنگی سائیڈ یا بیکٹیری سائیڈ لگائیں۔ '
          'مقامی زرعی دفتر سے رابطہ کریں۔',
    ),
    'fresh cotton leaf': _DiseaseInfo(
      displayName: 'Healthy Leaf',
      treatment:
      'No treatment required. Maintain regular monitoring schedule. '
          'Continue current irrigation and fertilization practices.',
      treatmentUrdu:
      'علاج کی ضرورت نہیں۔ باقاعدہ نگرانی جاری رکھیں۔ '
          'موجودہ آبپاشی اور کھاد کا عمل جاری رکھیں۔',
      isHealthy: true,
    ),
    'fresh cotton plant': _DiseaseInfo(
      displayName: 'Healthy Plant',
      treatment:
      'Plant appears healthy. Continue regular monitoring. '
          'Maintain proper spacing for air circulation. '
          'Follow standard IPM (Integrated Pest Management) practices.',
      treatmentUrdu:
      'پودا صحت مند ہے۔ باقاعدہ نگرانی جاری رکھیں۔ '
          'مناسب فاصلہ برقرار رکھیں۔ آئی پی ایم طریقے اپنائیں۔',
      isHealthy: true,
    ),
  };

  // ── Initialize once ───────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      // Wait for ongoing init rather than double-initializing
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _initializing = true;
    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/cotton_leaf_model.tflite',
        options: options,
      );

      final labelsJson =
      await rootBundle.loadString('assets/models/labels.json');
      final Map<String, dynamic> raw = json.decode(labelsJson);
      _labels = raw.map((k, v) => MapEntry(int.parse(k), v as String));

      _initialized = true;
    } catch (e) {
      _initializing = false;
      throw Exception('Model initialization failed: $e');
    }
    _initializing = false;
  }

  // ── Build tensor in isolate — no main-thread GC pressure ──
  static Future<List?> _buildTensorInIsolate(Uint8List imageBytes) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _buildTensorIsolate,
      _TensorMessage(receivePort.sendPort, imageBytes),
    );
    final result = await receivePort.first;
    receivePort.close();
    if (result == null) return null;

    // Reshape Float32List → [1, 224, 224, 3] nested list for tflite_flutter
    final flat = result as Float32List;
    return List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) => [
            flat[(y * 224 + x) * 3],
            flat[(y * 224 + x) * 3 + 1],
            flat[(y * 224 + x) * 3 + 2],
          ],
        ),
      ),
    );
  }

  // ── Main inference ────────────────────────────────────────
  static Future<DetectionResult?> detectDisease(File imageFile) async {
    if (!_initialized) await initialize();
    if (_interpreter == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final inputTensor = await _buildTensorInIsolate(bytes);
      if (inputTensor == null) return null;

      final numClasses = _labels.length;
      final outputTensor =
      List.filled(numClasses, 0.0).reshape([1, numClasses]);

      _interpreter!.run(inputTensor, outputTensor);

      final scores = List<double>.from(outputTensor[0] as List);
      double maxScore = 0;
      int maxIndex = 0;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      final diseaseKey = _labels[maxIndex] ?? 'unknown';
      final info = _diseaseDb[diseaseKey];

      return DetectionResult(
        diseaseKey: diseaseKey,
        displayName: info?.displayName ?? diseaseKey,
        confidence: maxScore,
        severity: _getSeverity(maxScore, info?.isHealthy ?? false),
        severityUrdu: _getSeverityUrdu(maxScore, info?.isHealthy ?? false),
        treatment: info?.treatment ?? 'Consult an agricultural expert.',
        treatmentUrdu: info?.treatmentUrdu ?? 'زرعی ماہر سے مشورہ کریں۔',
        isHealthy: info?.isHealthy ?? false,
        heatmapData: [],
      );
    } catch (e) {
      return null;
    }
  }

  // ── Cancel ongoing heatmap (call before new scan) ─────────
  static void cancelHeatmap() {
    _heatmapCancelled = true;
  }

  // ── Heatmap via occlusion — cancellable, async, 49 passes ─
  static Future<List<List<double>>> computeHeatmap(
      File imageFile,
      int targetClassIndex,
      ) async {
    if (!_initialized || _interpreter == null) return [];
    _heatmapCancelled = false;

    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return [];
      image = img.copyResize(image, width: 224, height: 224);
      return await _generateAttentionMap(image, targetClassIndex);
    } catch (e) {
      return [];
    }
  }

  static Future<List<List<double>>> _generateAttentionMap(
      img.Image originalImage,
      int targetClass,
      ) async {
    const gridSize = 7;
    const patchSize = 32;
    final heatmap =
    List.generate(gridSize, (_) => List.filled(gridSize, 0.0));

    final baseScore = _inferScoreSync(originalImage, targetClass);

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        // Check cancellation each patch
        if (_heatmapCancelled) return [];

        final occluded =
        img.copyResize(originalImage, width: 224, height: 224);
        final pxStart = gx * patchSize;
        final pyStart = gy * patchSize;

        for (int py = pyStart; py < min(pyStart + patchSize, 224); py++) {
          for (int px = pxStart; px < min(pxStart + patchSize, 224); px++) {
            occluded.setPixelRgb(px, py, 128, 128, 128);
          }
        }

        final occScore = _inferScoreSync(occluded, targetClass);
        heatmap[gy][gx] = max(0, baseScore - occScore);

        // Yield to event loop after each row to avoid ANR
        if (gx == gridSize - 1) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    // Normalize
    double maxVal = 0;
    for (var row in heatmap) {
      for (var v in row) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal > 0) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          heatmap[y][x] /= maxVal;
        }
      }
    }
    return heatmap;
  }

  // Sync inference — used only inside heatmap loop (already async-yielding)
  static double _inferScoreSync(img.Image image, int targetClass) {
    final inputTensor = _buildTensorSync(image);
    final numClasses = _labels.length;
    final outputTensor =
    List.filled(numClasses, 0.0).reshape([1, numClasses]);
    _interpreter!.run(inputTensor, outputTensor);
    return (outputTensor[0] as List)[targetClass].toDouble();
  }

  static List _buildTensorSync(img.Image image) {
    return List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  static int getLabelIndex(String diseaseKey) {
    for (final entry in _labels.entries) {
      if (entry.value == diseaseKey) return entry.key;
    }
    return 0;
  }

  static String _getSeverity(double confidence, bool isHealthy) {
    if (isHealthy) return 'None';
    if (confidence >= 0.85) return 'High';
    if (confidence >= 0.65) return 'Moderate';
    return 'Low';
  }

  static String _getSeverityUrdu(double confidence, bool isHealthy) {
    if (isHealthy) return 'کوئی نہیں';
    if (confidence >= 0.85) return 'زیادہ';
    if (confidence >= 0.65) return 'متوسط';
    return 'کم';
  }

  // ── Dispose — only call when app exits, NOT between scans ─
  static void dispose() {
    _heatmapCancelled = true;
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
    _initializing = false;
  }
}