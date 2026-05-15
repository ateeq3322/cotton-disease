// lib/widgets/gradcam_overlay_widget.dart
// ─────────────────────────────────────────────────────────────
// Renders 7x7 Grad-CAM heatmap overlaid on leaf image
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';

class GradCamOverlayWidget extends StatelessWidget {
  final File imageFile;
  final List<List<double>> heatmapData; // 7x7 grid, values 0-1
  final double alpha;
  final double height;

  const GradCamOverlayWidget({
    super.key,
    required this.imageFile,
    required this.heatmapData,
    this.alpha = 0.45,
    this.height = 280,
  });

  // Jet colormap: 0=blue → 0.5=green → 1=red
  Color _jetColor(double value) {
    final v = value.clamp(0.0, 1.0);
    double r, g, b;

    if (v < 0.25) {
      r = 0;
      g = 4 * v;
      b = 1;
    } else if (v < 0.5) {
      r = 0;
      g = 1;
      b = 1 - 4 * (v - 0.25);
    } else if (v < 0.75) {
      r = 4 * (v - 0.5);
      g = 1;
      b = 0;
    } else {
      r = 1;
      g = 1 - 4 * (v - 0.75);
      b = 0;
    }

    return Color.fromRGBO(
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
      alpha,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(imageFile, fit: BoxFit.cover),
            if (heatmapData.isNotEmpty)
              CustomPaint(
                painter: _HeatmapPainter(
                  heatmapData: heatmapData,
                  jetColor: _jetColor,
                ),
              ),
            Positioned(
              right: 8,
              top: 8,
              child: _ColorScaleLegend(jetColor: _jetColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<List<double>> heatmapData;
  final Color Function(double) jetColor;

  _HeatmapPainter({required this.heatmapData, required this.jetColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridH = heatmapData.length;
    if (gridH == 0) return;
    final gridW = heatmapData[0].length;

    final cellW = size.width / gridW;
    final cellH = size.height / gridH;

    for (int y = 0; y < gridH; y++) {
      for (int x = 0; x < gridW; x++) {
        final value = heatmapData[y][x];
        final paint = Paint()..color = jetColor(value);
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.heatmapData != heatmapData;
}

class _ColorScaleLegend extends StatelessWidget {
  final Color Function(double) jetColor;

  const _ColorScaleLegend({required this.jetColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            jetColor(1.0).withOpacity(1),
            jetColor(0.75).withOpacity(1),
            jetColor(0.5).withOpacity(1),
            jetColor(0.25).withOpacity(1),
            jetColor(0.0).withOpacity(1),
          ],
        ),
      ),
    );
  }
}