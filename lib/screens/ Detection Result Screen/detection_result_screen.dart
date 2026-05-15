// lib/screens/Detection Result Screen/detection_result_screen.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Detection result screen
// Provider state, brand fonts/colors, PDF export, Firestore save
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Provider/detection_provider.dart';
import '../../utils/gradcam_overlay_widget.dart';
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
      provider.reset();
      provider.runDetection(widget.imageFile).then((_) {
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
    });
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
                IconButton(
                  icon: provider.isGeneratingPdf
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: brandGreen),
                  )
                      : Icon(Icons.picture_as_pdf_outlined,
                      color: textColor, size: 22),
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
                  tooltip: provider.savedToHistory
                      ? 'Saved'
                      : 'Save to history',
                  onPressed:
                  (provider.savedToHistory || provider.isSaving)
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

  Widget _buildBody(
      DetectionProvider provider, bool isDark, Color textColor) {
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
                  backgroundColor: isDark
                      ? const Color(0xFF1E2D24)
                      : const Color(0xFFDCFCE7),
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
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: mediumGray,
            ),
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
              child:
              const Icon(Icons.error_outline_rounded, size: 48, color: errorRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Detection Failed',
              style: GoogleFonts.saira(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Could not analyze the image.\nPlease try again with a clearer photo.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: mediumGray,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(
                'Try Again',
                style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
      DetectionProvider provider, bool isDark, Color textColor) {
    final result = provider.result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildImageSection(provider, isDark),
          const SizedBox(height: 20),
          _buildResultCard(provider, result, isDark, textColor),
          const SizedBox(height: 16),
          _buildStatsRow(provider, result, isDark),
          const SizedBox(height: 20),
          _buildTreatmentCard(result, isDark, textColor),
          const SizedBox(height: 24),
          _buildActionButtons(provider, isDark),
        ],
      ),
    );
  }

  Widget _buildImageSection(DetectionProvider provider, bool isDark) {
    final result = provider.result!;
    return Column(
      children: [
        // Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (provider.heatmapComputing) ...[
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: brandGreen),
              ),
              const SizedBox(width: 6),
              Text(
                'Computing Grad-CAM',
                style: GoogleFonts.quicksand(
                    fontSize: 11,
                    color: mediumGray,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Grad-CAM',
              style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w600),
            ),
            Switch(
              value: provider.showHeatmap,
              onChanged: provider.heatmapReady
                  ? (v) => provider.toggleHeatmap(v)
                  : null,
              activeColor: brandGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Image
        Container(
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: (provider.showHeatmap && provider.heatmapReady)
                  ? GradCamOverlayWidget(
                key: const ValueKey('heatmap'),
                imageFile: widget.imageFile,
                heatmapData: result.heatmapData,
                height: 280,
              )
                  : SizedBox(
                key: const ValueKey('original'),
                height: 280,
                width: double.infinity,
                child: Image.file(widget.imageFile, fit: BoxFit.cover),
              ),
            ),
          ),
        ),

        if (provider.showHeatmap && provider.heatmapReady)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Red = high disease probability  ·  Blue = low',
              style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: mediumGray,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        if (provider.heatmapComputing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Generating attention heatmap in background...',
              style: GoogleFonts.quicksand(
                  fontSize: 11,
                  color: mediumGray,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(DetectionProvider provider, result,
      bool isDark, Color textColor) {
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

  Widget _buildStatsRow(
      DetectionProvider provider, result, bool isDark) {
    final sColor = _severityColor(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Model Confidence',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w500),
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
              backgroundColor: isDark
                  ? const Color(0xFF2A3530)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(sColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _SeverityChip(label: 'Severity: ${result.severity}', color: sColor),
            const SizedBox(width: 8),
            _SeverityChip(
                label: result.severityUrdu, color: sColor, isUrdu: true),
          ],
        ),
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
          // Header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  isHealthy
                      ? Icons.eco_rounded
                      : Icons.medication_liquid_rounded,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.treatment,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.7,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                    color: isDark
                        ? const Color(0xFF2E3830)
                        : const Color(0xFFE5EAE5)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اردو ہدایات',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    result.treatmentUrdu,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 2.0,
                      fontFamily: 'NotoNastaliqUrdu',
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DetectionProvider provider, bool isDark) {
    return Column(
      children: [
        // Save to history
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
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: white),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              provider.savedToHistory ? const Color(0xFF16A34A) : brandGreen,
              foregroundColor: white,
              disabledBackgroundColor: provider.savedToHistory
                  ? const Color(0xFF16A34A)
                  : null,
              disabledForegroundColor: white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Export PDF
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
              provider.isGeneratingPdf
                  ? 'Generating PDF...'
                  : 'Download PDF Report',
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isDark ? lightGrayBlack : const Color(0xFFF0FDF4),
              foregroundColor: brandGreen,
              side: BorderSide(color: brandGreen.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Scan another
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              'Scan Another Leaf',
              style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.3),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? lightGray : darkGray,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF3A4A40)
                    : const Color(0xFFD1D5DB),
              ),
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
    switch (r.severity) {
      case 'High':
        return errorRed;
      case 'Moderate':
        return warningYellow;
      default:
        return const Color(0xFFEAB308);
    }
  }

  IconData _severityIcon(DetectionProvider provider) {
    final r = provider.result;
    if (r?.isHealthy == true) return Icons.check_circle_rounded;
    switch (r?.severity) {
      case 'High':
        return Icons.warning_rounded;
      case 'Moderate':
        return Icons.info_rounded;
      default:
        return Icons.remove_circle_outline_rounded;
    }
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isUrdu;

  const _SeverityChip({
    required this.label,
    required this.color,
    this.isUrdu = false,
  });

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
        style: isUrdu
            ? TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'NotoNastaliqUrdu',
          fontWeight: FontWeight.w600,
        )
            : GoogleFonts.quicksand(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }
}