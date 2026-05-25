// lib/services/disease_detection_service.dart
// ─────────────────────────────────────────────────────────────
// FIX: Isolate messaging now uses ONLY primitive types.
// _HeatmapMessage and _HeatmapResult replaced with plain List
// and Map — the only types Dart isolates can send across ports.
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ── Result model ──────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// TOP-LEVEL ISOLATE FUNCTIONS
// Must be top-level. Must send/receive ONLY primitives:
//   bool, int, double, String, Uint8List, List, Map, null
// NO custom classes across isolate boundary.
// ─────────────────────────────────────────────────────────────

// ── Main inference tensor builder ────────────────────────────
// Receives: List [SendPort, Uint8List]
// Sends:    Float32List | null
void _buildTensorIsolate(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final imageBytes = args[1] as Uint8List;
  try {
    final image = img.decodeImage(imageBytes);
    if (image == null) { sendPort.send(null); return; }
    final resized = img.copyResize(image, width: 224, height: 224);

    final tensor = Float32List(224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        tensor[idx++] = pixel.r / 255.0;
        tensor[idx++] = pixel.g / 255.0;
        tensor[idx++] = pixel.b / 255.0;
      }
    }
    sendPort.send(tensor);
  } catch (_) {
    sendPort.send(null);
  }
}

// ── Heatmap isolate ───────────────────────────────────────────
// Receives: List [SendPort, Uint8List imageBytes, Uint8List modelBytes,
//                 int targetClassIndex, int numClasses]
// Sends:    List<List<double>> (7x7) on success
//           empty List [] on failure
void _heatmapIsolate(List<dynamic> args) {
  final sendPort        = args[0] as SendPort;
  final imageBytes      = args[1] as Uint8List;
  final modelBytes      = args[2] as Uint8List;
  final targetClassIdx  = args[3] as int;
  final numClasses      = args[4] as int;

  Interpreter? interpreter;
  try {
    interpreter = Interpreter.fromBuffer(modelBytes);

    final image = img.decodeImage(imageBytes);
    if (image == null) { sendPort.send(<List<double>>[]); return; }
    final base = img.copyResize(image, width: 224, height: 224);

    // Build flat Float32List from image
    Float32List buildFlat(img.Image src) {
      final flat = Float32List(224 * 224 * 3);
      int i = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final p = src.getPixel(x, y);
          flat[i++] = p.r / 255.0;
          flat[i++] = p.g / 255.0;
          flat[i++] = p.b / 255.0;
        }
      }
      return flat;
    }

    // Run one inference pass, return score for target class
    double infer(Float32List flat) {
      final input = flat.reshape([1, 224, 224, 3]);
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
      interpreter!.run(input, output);
      return (output[0] as List)[targetClassIdx].toDouble();
    }

    final baseScore = infer(buildFlat(base));

    const gridSize = 7;
    const patchSize = 32;

    // Use List<List<double>> — primitive-safe
    final heatmap = List.generate(gridSize, (_) => List<double>.filled(gridSize, 0.0));

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        final occluded = img.copyResize(base, width: 224, height: 224);
        final pxStart = gx * patchSize;
        final pyStart = gy * patchSize;

        for (int py = pyStart; py < min(pyStart + patchSize, 224); py++) {
          for (int px = pxStart; px < min(pxStart + patchSize, 224); px++) {
            occluded.setPixelRgb(px, py, 128, 128, 128);
          }
        }

        final occScore = infer(buildFlat(occluded));
        heatmap[gy][gx] = max(0.0, baseScore - occScore);
      }
    }

    // Normalize 0→1
    double maxVal = 0;
    for (final row in heatmap) {
      for (final v in row) { if (v > maxVal) maxVal = v; }
    }
    if (maxVal > 0) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          heatmap[y][x] /= maxVal;
        }
      }
    }

    interpreter.close();
    // Send List<List<double>> — fully primitive, crosses isolate boundary safely
    sendPort.send(heatmap);
  } catch (e) {
    interpreter?.close();
    sendPort.send(<List<double>>[]);
  }
}

// ─────────────────────────────────────────────────────────────
// Main service
// ─────────────────────────────────────────────────────────────
class DiseaseDetectionService {
  static Interpreter? _interpreter;
  static Map<int, String> _labels = {};
  static bool _initialized = false;
  static bool _initializing = false;

  static Isolate? _heatmapIsolateRef;
  static bool _heatmapCancelled = false;

  // Raw model bytes — sent to heatmap isolate so it can build
  // its own interpreter without needing rootBundle
  static Uint8List? _modelBytes;

  static const Map<String, _DiseaseInfo> _diseaseDb = {
    'healthy': _DiseaseInfo(
      displayName: 'Healthy Leaf',
      treatment:
      'No treatment required. Maintain regular monitoring schedule. '
          'Continue current irrigation and fertilization practices.',
      treatmentUrdu:
      'علاج کی ضرورت نہیں۔ باقاعدہ نگرانی جاری رکھیں۔ '
          'موجودہ آبپاشی اور کھاد کا عمل جاری رکھیں۔',
      isHealthy: true,
    ),
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

  // ── Initialize ────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _initializing = true;
    try {
      final byteData = await rootBundle.load('assets/models/cotton_leaf_model.tflite');
      _modelBytes = byteData.buffer.asUint8List();

      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;

      _interpreter = Interpreter.fromBuffer(_modelBytes!, options: options);

      final labelsJson = await rootBundle.loadString('assets/models/labels.json');
      final Map<String, dynamic> raw = json.decode(labelsJson);
      _labels = raw.map((k, v) => MapEntry(int.parse(k), v as String));

      _initialized = true;
    } catch (e) {
      _initializing = false;
      throw Exception('Model initialization failed: $e');
    }
    _initializing = false;
  }

  // ── Build input tensor in isolate (main inference) ────────
  static Future<List?> _buildTensorInIsolate(Uint8List imageBytes) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _buildTensorIsolate,
      [receivePort.sendPort, imageBytes], // plain List — no custom class
    );
    final result = await receivePort.first;
    receivePort.close();
    if (result == null) return null;

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
      final outputTensor = List.filled(numClasses, 0.0).reshape([1, numClasses]);
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

      final diseaseKey = (_labels[maxIndex] ?? 'unknown').toLowerCase().trim();
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
    } catch (_) {
      return null;
    }
  }

  // ── Cancel heatmap ────────────────────────────────────────
  static void cancelHeatmap() {
    _heatmapCancelled = true;
    _heatmapIsolateRef?.kill(priority: Isolate.immediate);
    _heatmapIsolateRef = null;
  }

  // ── Heatmap — background isolate, primitives only ─────────
  static Future<List<List<double>>> computeHeatmap(
      File imageFile,
      int targetClassIndex,
      ) async {
    if (!_initialized || _interpreter == null || _modelBytes == null) return [];
    _heatmapCancelled = false;

    try {
      final imageBytes = await imageFile.readAsBytes();
      final numClasses = _labels.length;
      final receivePort = ReceivePort();

      _heatmapIsolateRef = await Isolate.spawn(
        _heatmapIsolate,
        // Plain List — all primitives, safe across isolate boundary
        [
          receivePort.sendPort,
          imageBytes,
          _modelBytes!,
          targetClassIndex,
          numClasses,
        ],
      );

      final raw = await receivePort.first;
      receivePort.close();
      _heatmapIsolateRef = null;

      if (_heatmapCancelled) return [];

      // Cast from dynamic
      final result = (raw as List).cast<List<double>>();
      return result.isEmpty ? [] : result;
    } catch (e, st) {
      print('HEATMAP ERROR: $e');
      print('STACK: $st');
      return [];
    }
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

  static void dispose() {
    cancelHeatmap();
    _interpreter?.close();
    _interpreter = null;
    _modelBytes = null;
    _initialized = false;
    _initializing = false;
  }
}