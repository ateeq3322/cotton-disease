// lib/providers/detection_provider.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Detection state provider
// Added: heatmap computation state + toggleHeatmap()
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../services/disease_detection_service.dart';
import 'WeatherProvider.dart';

enum DetectionStatus { idle, inferring, done, error }
enum SaveStatus { idle, saving, saved, failed }
enum PdfStatus { idle, generating, done, failed }
// NEW
enum HeatmapStatus { idle, computing, done, failed }

class DetectionProvider extends ChangeNotifier {
  DetectionResult? _result;
  DetectionStatus _status = DetectionStatus.idle;
  SaveStatus _saveStatus = SaveStatus.idle;
  PdfStatus _pdfStatus = PdfStatus.idle;
  String? _lastSnackMessage;
  bool _snackIsError = false;

  // Weather captured at detection time — null if unavailable
  WeatherSnapshot? _weatherSnapshot;

  // ── Heatmap state ─────────────────────────────────────────
  HeatmapStatus _heatmapStatus = HeatmapStatus.idle;
  List<List<double>> _heatmapData = [];
  bool _heatmapVisible = false;

  bool _alive = true;

  // ── Getters ───────────────────────────────────────────────
  DetectionResult? get result => _result;
  WeatherSnapshot? get weatherSnapshot => _weatherSnapshot;
  bool get isInferring => _status == DetectionStatus.inferring;
  bool get isDone => _status == DetectionStatus.done;
  bool get isError => _status == DetectionStatus.error;
  bool get savedToHistory => _saveStatus == SaveStatus.saved;
  bool get isSaving => _saveStatus == SaveStatus.saving;
  bool get isGeneratingPdf => _pdfStatus == PdfStatus.generating;
  String? get lastSnackMessage => _lastSnackMessage;
  bool get snackIsError => _snackIsError;

  // Heatmap getters
  bool get isComputingHeatmap => _heatmapStatus == HeatmapStatus.computing;
  bool get heatmapReady => _heatmapStatus == HeatmapStatus.done && _heatmapData.isNotEmpty;
  bool get heatmapVisible => _heatmapVisible;
  List<List<double>> get heatmapData => _heatmapData;

  void _safeNotify() {
    if (_alive) notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────
  void reset() {
    _result = null;
    _status = DetectionStatus.idle;
    _saveStatus = SaveStatus.idle;
    _pdfStatus = PdfStatus.idle;
    _weatherSnapshot = null;
    _lastSnackMessage = null;
    _heatmapStatus = HeatmapStatus.idle;
    _heatmapData = [];
    _heatmapVisible = false;
    DiseaseDetectionService.cancelHeatmap();
    _safeNotify();
  }

  void clearSnack() {
    _lastSnackMessage = null;
  }

  // ── Step 1: Inference + Weather snapshot ──────────────────
  Future<void> runDetection(
      File imageFile,
      WeatherProvider weatherProvider,
      ) async {
    _status = DetectionStatus.inferring;
    _safeNotify();

    try {
      final results = await Future.wait([
        DiseaseDetectionService.detectDisease(imageFile),
        weatherProvider.getSnapshot(),
      ]);

      if (!_alive) return;

      final DetectionResult? detectionResult = results[0] as DetectionResult?;
      final WeatherSnapshot? snapshot = results[1] as WeatherSnapshot?;

      if (detectionResult == null) {
        _status = DetectionStatus.error;
        _safeNotify();
        return;
      }

      _result = detectionResult;
      _weatherSnapshot = snapshot;
      _status = DetectionStatus.done;
      _safeNotify();
    } catch (_) {
      if (!_alive) return;
      _status = DetectionStatus.error;
      _safeNotify();
    }
  }

  // ── NEW: Toggle heatmap ───────────────────────────────────
  // If healthy → caller should show snackbar, don't call this.
  // If disease → compute on first toggle, then just flip visibility.
  Future<void> toggleHeatmap(File imageFile) async {
    if (_result == null || _result!.isHealthy) return;

    // Already computed — just flip visibility
    if (heatmapReady) {
      _heatmapVisible = !_heatmapVisible;
      _safeNotify();
      return;
    }

    // Currently computing — ignore tap
    if (isComputingHeatmap) return;

    // First time: compute
    _heatmapStatus = HeatmapStatus.computing;
    _heatmapVisible = false;
    _safeNotify();

    try {
      final labelIndex = DiseaseDetectionService.getLabelIndex(_result!.diseaseKey);
      final data = await DiseaseDetectionService.computeHeatmap(imageFile, labelIndex);

      if (!_alive) return;

      if (data.isEmpty) {
        _heatmapStatus = HeatmapStatus.failed;
        _setSnack('Heatmap computation failed.', isError: true);
        _safeNotify();
        return;
      }

      _heatmapData = data;
      _heatmapStatus = HeatmapStatus.done;
      _heatmapVisible = true; // auto-show after first compute
      _safeNotify();
    } catch (e) {
      if (!_alive) return;
      _heatmapStatus = HeatmapStatus.failed;
      _setSnack('Heatmap error: $e', isError: true);
      _safeNotify();
    }
  }

  // ── Save to Firestore ─────────────────────────────────────
  Future<void> saveToHistory(File imageFile) async {
    if (_result == null || _saveStatus == SaveStatus.saved) return;

    _saveStatus = SaveStatus.saving;
    _safeNotify();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _saveStatus = SaveStatus.failed;
        _setSnack('Not logged in. Cannot save.', isError: true);
        _safeNotify();
        return;
      }

      double? lat, lng;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}

      if (!_alive) return;

      final Map<String, dynamic> doc = {
        'diseaseKey': _result!.diseaseKey,
        'displayName': _result!.displayName,
        'confidence': _result!.confidence,
        'severity': _result!.severity,
        'isHealthy': _result!.isHealthy,
        'treatment': _result!.treatment,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'weatherCity': _weatherSnapshot?.cityName,
        'weatherTemp': _weatherSnapshot?.temperatureCelsius,
        'weatherMain': _weatherSnapshot?.weatherMain,
        'weatherHumidity': _weatherSnapshot?.humidity,
        'weatherWindSpeed': _weatherSnapshot?.windSpeed,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('detections')
          .add(doc);

      if (!_alive) return;
      _saveStatus = SaveStatus.saved;
      _setSnack('Report saved to history ✓');
    } catch (e) {
      if (!_alive) return;
      _saveStatus = SaveStatus.failed;
      _setSnack('Save failed: $e', isError: true);
    }
    _safeNotify();
  }

  // ── Export PDF ────────────────────────────────────────────
  Future<String?> exportPdf(File imageFile) async {
    if (_result == null) return null;

    _pdfStatus = PdfStatus.generating;
    _setSnack('Generating PDF report...');
    _safeNotify();

    try {
      final pdf = pw.Document();
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      final font = await pw.Font.ttf(
        await rootBundle.load('assets/fonts/Abel-Regular.ttf'),
      );

      final now = DateTime.now();
      final dateStr =
          '${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final String weatherStr = _weatherSnapshot != null
          ? '${_weatherSnapshot!.cityName}  ·  ${_weatherSnapshot!.tempFormatted}  ·  ${_weatherSnapshot!.weatherMain}'
          : 'Weather data unavailable';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#44B678'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CropGuard',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 4),
                    pw.Text('Cotton Disease Detection Report',
                        style: pw.TextStyle(font: font, fontSize: 13, color: PdfColors.white)),
                    pw.SizedBox(height: 4),
                    pw.Text('Generated: $dateStr',
                        style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex('#d4f5e4'))),
                    pw.SizedBox(height: 2),
                    pw.Text('Field Conditions: $weatherStr',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('#d4f5e4'))),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 200,
                    height: 200,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(pdfImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfLabel('Detection Result', font),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _result!.displayName,
                          style: pw.TextStyle(
                            font: font,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: _result!.isHealthy
                                ? PdfColor.fromHex('#22C55E')
                                : PdfColor.fromHex('#EF4444'),
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        _pdfLabel('Confidence', font),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${(_result!.confidence * 100).toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                        pw.SizedBox(height: 12),
                        _pdfLabel('Severity', font),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: _result!.isHealthy
                                ? PdfColor.fromHex('#DCFCE7')
                                : _result!.severity == 'High'
                                ? PdfColor.fromHex('#FEE2E2')
                                : PdfColor.fromHex('#FEF3C7'),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            _result!.severity,
                            style: pw.TextStyle(
                              font: font,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: _result!.isHealthy
                                  ? PdfColor.fromHex('#15803D')
                                  : _result!.severity == 'High'
                                  ? PdfColor.fromHex('#DC2626')
                                  : PdfColor.fromHex('#92400E'),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        _pdfLabel('Status', font),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _result!.isHealthy ? 'Healthy' : 'Disease Detected',
                          style: pw.TextStyle(
                            font: font,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                            color: _result!.isHealthy
                                ? PdfColor.fromHex('#22C55E')
                                : PdfColor.fromHex('#EF4444'),
                          ),
                        ),
                        if (_weatherSnapshot != null) ...[
                          pw.SizedBox(height: 12),
                          _pdfLabel('Field Conditions', font),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${_weatherSnapshot!.cityName}',
                            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 12),
                          ),
                          pw.Text(
                            '${_weatherSnapshot!.tempFormatted}  ·  ${_weatherSnapshot!.weatherMain}  ·  Humidity ${_weatherSnapshot!.humidity.toStringAsFixed(0)}%',
                            style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
              pw.SizedBox(height: 16),
              pw.Text('Recommended Action',
                  style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _result!.isHealthy
                      ? PdfColor.fromHex('#F0FDF4')
                      : PdfColor.fromHex('#FFF7ED'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: _result!.isHealthy
                        ? PdfColor.fromHex('#BBF7D0')
                        : PdfColor.fromHex('#FED7AA'),
                  ),
                ),
                child: pw.Text(
                  _result!.treatment,
                  style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 4),
                ),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CropGuard — AI Cotton Disease Detection',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
                  pw.Text('For agricultural use only. Consult an expert for confirmation.',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = now.millisecondsSinceEpoch;
      final filePath = '${dir.path}/cropguard_report_$timestamp.pdf';
      await File(filePath).writeAsBytes(await pdf.save());

      if (!_alive) return null;
      _pdfStatus = PdfStatus.done;
      _setSnack('PDF saved to Documents ✓');
      _safeNotify();

      await OpenFile.open(filePath);
      return filePath;
    } catch (e) {
      if (!_alive) return null;
      _pdfStatus = PdfStatus.failed;
      _setSnack('PDF export failed: $e', isError: true);
      _safeNotify();
      return null;
    }
  }

  pw.Widget _pdfLabel(String text, pw.Font font) => pw.Text(
    text.toUpperCase(),
    style: pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey,
      letterSpacing: 0.8,
    ),
  );

  void _setSnack(String message, {bool isError = false}) {
    _lastSnackMessage = message;
    _snackIsError = isError;
  }

  @override
  void dispose() {
    _alive = false;
    DiseaseDetectionService.cancelHeatmap();
    super.dispose();
  }
}