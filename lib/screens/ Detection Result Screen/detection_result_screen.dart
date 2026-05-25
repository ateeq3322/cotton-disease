// lib/screens/Detection Result Screen/detection_result_screen.dart
// ─────────────────────────────────────────────────────────────
// Added: heatmap toggle button + HeatmapPainter overlay on image
// Healthy leaf → snackbar only, no heatmap computed
// Disease detected → toggle button in AppBar + overlay on image
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Provider/WeatherProvider.dart';
import '../../Provider/detection_provider.dart';
import '../../utils/constants/colors.dart';
import '../../Provider/ThemeProvider.dart';

class DetectionResultScreen extends StatefulWidget {
  final File imageFile;
  const DetectionResultScreen({super.key, required this.imageFile});

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DetectionProvider>();
      final weatherProvider = context.read<WeatherProvider>();
      provider.reset();
      provider.runDetection(widget.imageFile, weatherProvider).then((_) {
        if (mounted && provider.isDone) _fadeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _maybeShowSnack(DetectionProvider provider) {
    final msg = provider.lastSnackMessage;
    if (msg == null) return;
    provider.clearSnack();
    final isError = provider.snackIsError;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? errorRed : brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  // ── Heatmap toggle handler ────────────────────────────────
  void _onHeatmapTap(DetectionProvider provider) {
    if (provider.result == null) return;

    // Healthy leaf — don't compute heatmap, just inform user
    if (provider.result!.isHealthy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.eco_rounded, color: white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Leaf is healthy — no disease spots detected.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Disease detected — compute or toggle
    provider.toggleHeatmap(widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    return Consumer<DetectionProvider>(
      builder: (context, provider, _) {
        _maybeShowSnack(provider);

        final bg = isDark ? darkBlack : const Color(0xFFF4F6F4);
        final appBarBg = isDark ? lightGrayBlack : white;
        final textColor = isDark ? white : carbonBlack;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Text(
              'Detection Result',
              style: GoogleFonts.saira(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            centerTitle: true,
            actions: [
              if (provider.isDone && provider.result != null) ...[
                // ── Heatmap toggle button ─────────────────────
                _HeatmapAppBarButton(
                  provider: provider,
                  onTap: () => _onHeatmapTap(provider),
                  textColor: textColor,
                ),
                IconButton(
                  icon: provider.isGeneratingPdf
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: brandGreen),
                  )
                      : Icon(Icons.picture_as_pdf_outlined, color: textColor, size: 22),
                  tooltip: 'Export PDF',
                  onPressed: provider.isGeneratingPdf
                      ? null
                      : () => provider.exportPdf(widget.imageFile),
                ),
                IconButton(
                  icon: Icon(
                    provider.savedToHistory
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: provider.savedToHistory ? brandGreen : textColor,
                    size: 22,
                  ),
                  tooltip: provider.savedToHistory ? 'Saved' : 'Save to history',
                  onPressed: (provider.savedToHistory || provider.isSaving)
                      ? null
                      : () => provider.saveToHistory(widget.imageFile),
                ),
              ],
            ],
          ),
          body: _buildBody(provider, isDark, textColor),
        );
      },
    );
  }

  Widget _buildBody(DetectionProvider provider, bool isDark, Color textColor) {
    if (provider.isInferring) return _buildLoading(isDark);
    if (provider.isError || provider.result == null) {
      return _buildError(isDark, textColor);
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildResult(provider, isDark, textColor),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: brandGreen,
                  backgroundColor:
                  isDark ? const Color(0xFF1E2D24) : const Color(0xFFDCFCE7),
                ),
              ),
              const Icon(Icons.eco_rounded, size: 30, color: brandGreen),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Image',
            style: GoogleFonts.saira(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? white : carbonBlack,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Running AI detection on your cotton leaf...',
            style: GoogleFonts.montserrat(fontSize: 13, color: mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: errorRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Detection Failed',
              style: GoogleFonts.saira(
                  fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Could not analyze the image.\nPlease try again with a clearer photo.',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: mediumGray, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text('Try Again',
                  style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(DetectionProvider provider, bool isDark, Color textColor) {
    final result = provider.result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // ── Image + heatmap overlay ─────────────────────────
          _buildImageSection(provider, isDark),
          const SizedBox(height: 20),
          _buildResultCard(provider, result, isDark, textColor),
          const SizedBox(height: 16),
          _buildStatsRow(provider, result, isDark),
          const SizedBox(height: 12),
          if (provider.weatherSnapshot != null)
            _buildWeatherChip(provider.weatherSnapshot!, isDark),
          const SizedBox(height: 20),
          _buildTreatmentCard(result, isDark, textColor),
          const SizedBox(height: 24),
          _buildActionButtons(provider, isDark),
        ],
      ),
    );
  }

  // ── Image section with heatmap overlay ───────────────────
  Widget _buildImageSection(DetectionProvider provider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base image
              Image.file(widget.imageFile, fit: BoxFit.cover),

              // Heatmap overlay — only shown when visible & ready
              if (provider.heatmapVisible && provider.heatmapReady)
                AnimatedOpacity(
                  opacity: provider.heatmapVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: CustomPaint(
                    painter: HeatmapPainter(provider.heatmapData),
                  ),
                ),

              // Computing spinner overlay
              if (provider.isComputingHeatmap)
                Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: warningYellow,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Computing disease map...',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Heatmap legend badge — bottom left, shown when overlay is visible
              if (provider.heatmapVisible && provider.heatmapReady)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _HeatmapLegend(),
                ),

              // Toggle tap hint — bottom right when result is disease
              if (provider.isDone &&
                  provider.result != null &&
                  !provider.result!.isHealthy &&
                  !provider.isComputingHeatmap)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => provider.toggleHeatmap(widget.imageFile),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: provider.heatmapVisible
                            ? warningYellow
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: provider.heatmapVisible
                              ? warningYellow
                              : Colors.white30,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.heatmapVisible
                                ? Icons.visibility_off_rounded
                                : Icons.thermostat_rounded,
                            size: 14,
                            color: white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            provider.heatmapVisible
                                ? 'Hide Map'
                                : 'Disease Map',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherChip(WeatherSnapshot snapshot, bool isDark) {
    final parts = <String>[];
    if (snapshot.cityName.isNotEmpty && snapshot.cityName != 'Unknown') {
      parts.add(snapshot.cityName);
    }
    parts.add(snapshot.tempFormatted);
    if (snapshot.weatherMain.isNotEmpty && snapshot.weatherMain != 'Unknown') {
      parts.add(snapshot.weatherMain);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D24) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandGreen.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 14, color: brandGreen),
          const SizedBox(width: 6),
          Text(
            'Field conditions\n ${parts.join('  ·  ')}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: brandGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
      DetectionProvider provider, result, bool isDark, Color textColor) {
    final sColor = _severityColor(provider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? lightGrayBlack : white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_severityIcon(provider), color: sColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  style: GoogleFonts.saira(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: mediumGray,
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: sColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.severity,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DetectionProvider provider, result, bool isDark) {
    final sColor = _severityColor(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Model Confidence',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: mediumGray, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '${(result.confidence * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.saira(
                  fontSize: 13, fontWeight: FontWeight.w700, color: sColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: result.confidence),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor:
              isDark ? const Color(0xFF2A3530) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(sColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SeverityChip(label: 'Severity: ${result.severity}', color: sColor),
      ],
    );
  }

  Widget _buildTreatmentCard(result, bool isDark, Color textColor) {
    final isHealthy = result.isHealthy;
    final accent = isHealthy ? brandGreen : warningYellow;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? lightGrayBlack : white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isHealthy ? Icons.eco_rounded : Icons.medication_liquid_rounded,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended Action',
                  style: GoogleFonts.saira(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              result.treatment,
              style: GoogleFonts.montserrat(
                  fontSize: 13, height: 1.7, color: textColor, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DetectionProvider provider, bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (provider.savedToHistory || provider.isSaving)
                ? null
                : () => provider.saveToHistory(widget.imageFile),
            icon: provider.isSaving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: white),
            )
                : Icon(
                provider.savedToHistory
                    ? Icons.check_rounded
                    : Icons.history_rounded,
                size: 18),
            label: Text(
              provider.isSaving
                  ? 'Saving...'
                  : provider.savedToHistory
                  ? 'Saved to History'
                  : 'Save to History',
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              provider.savedToHistory ? const Color(0xFF16A34A) : brandGreen,
              foregroundColor: white,
              disabledBackgroundColor:
              provider.savedToHistory ? const Color(0xFF16A34A) : null,
              disabledForegroundColor: white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.isGeneratingPdf
                ? null
                : () => provider.exportPdf(widget.imageFile),
            icon: provider.isGeneratingPdf
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: brandGreen),
            )
                : const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(
              provider.isGeneratingPdf ? 'Generating PDF...' : 'Download PDF Report',
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isDark ? lightGrayBlack : const Color(0xFFF0FDF4),
              foregroundColor: brandGreen,
              side: BorderSide(color: brandGreen.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              'Scan Another Leaf',
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? lightGray : darkGray,
              side: BorderSide(
                  color: isDark
                      ? const Color(0xFF3A4A40)
                      : const Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
      ],
    );
  }

  Color _severityColor(DetectionProvider provider) {
    final r = provider.result;
    if (r == null) return mediumGray;
    if (r.isHealthy) return brandGreen;
    if (r.confidence >= 0.90) return errorRed;
    if (r.confidence >= 0.70) return warningYellow;
    return const Color(0xFFEAB308);
  }

  IconData _severityIcon(DetectionProvider provider) {
    final r = provider.result;
    if (r == null) return Icons.help_outline_rounded;
    if (r.isHealthy) return Icons.check_circle_rounded;
    if (r.confidence >= 0.90) return Icons.warning_rounded;
    if (r.confidence >= 0.70) return Icons.info_rounded;
    return Icons.remove_circle_outline_rounded;
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar heatmap button — shows spinner while computing
// ─────────────────────────────────────────────────────────────
class _HeatmapAppBarButton extends StatelessWidget {
  final DetectionProvider provider;
  final VoidCallback onTap;
  final Color textColor;

  const _HeatmapAppBarButton({
    required this.provider,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isComputingHeatmap) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: warningYellow),
        ),
      );
    }

    final isHealthy = provider.result?.isHealthy ?? true;
    final isActive = provider.heatmapVisible;

    return IconButton(
      icon: Icon(
        Icons.thermostat_rounded,
        color: isHealthy
            ? textColor.withOpacity(0.4)
            : isActive
            ? warningYellow
            : textColor,
        size: 22,
      ),
      tooltip: isHealthy ? 'Leaf is healthy' : 'Toggle disease heatmap',
      onPressed: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HeatmapPainter — renders 7x7 grid as transparent color overlay
// Green (low) → Yellow → Red (high disease probability)
// ─────────────────────────────────────────────────────────────
class HeatmapPainter extends CustomPainter {
  final List<List<double>> heatmapData;

  const HeatmapPainter(this.heatmapData);

  @override
  void paint(Canvas canvas, Size size) {
    if (heatmapData.isEmpty) return;

    final rows = heatmapData.length;
    final cols = heatmapData[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final value = heatmapData[y][x].clamp(0.0, 1.0);
        if (value < 0.05) continue; // skip near-zero cells — keeps healthy areas clean

        final color = _heatColor(value);
        final paint = Paint()..color = color;

        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);

        // Rounded rects for cleaner look
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(4)),
          paint,
        );
      }
    }
  }

  // Maps 0→1 to green→yellow→red with variable opacity
  Color _heatColor(double value) {
    final opacity = (0.25 + value * 0.55).clamp(0.0, 0.80);

    if (value < 0.5) {
      // Green → Yellow
      final t = value / 0.5;
      return Color.fromRGBO(
        (255 * t).round(),        // R: 0→255
        200,                       // G: stays high
        0,                         // B
        opacity,
      );
    } else {
      // Yellow → Red
      final t = (value - 0.5) / 0.5;
      return Color.fromRGBO(
        255,                       // R: stays 255
        (200 * (1 - t)).round(),   // G: 200→0
        0,
        opacity,
      );
    }
  }

  @override
  bool shouldRepaint(HeatmapPainter old) =>
      old.heatmapData != heatmapData;
}

// ─────────────────────────────────────────────────────────────
// Heatmap legend — bottom left of image
// ─────────────────────────────────────────────────────────────
class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient bar
          Container(
            width: 50,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF22C55E), // green — healthy
                  Color(0xFFEAB308), // yellow — moderate
                  Color(0xFFEF4444), // red — high disease
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Disease intensity',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}