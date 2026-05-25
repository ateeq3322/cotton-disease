import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
class AboutCottonSenseScreen extends StatelessWidget {
  const AboutCottonSenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = Provider.of<DarkModeProvider>(context).isDarkMode;

    final backgroundColor = darkMode ? darkBlack : white;
    final appBarColor    = darkMode ? lightGrayBlack : white;
    final textColor      = darkMode ? white : carbonBlack;
    final subtitleColor  = darkMode ? lightGray : mediumGray;
    final cardColor      = darkMode ? lightGrayBlack : cardBg;
    final iconBgColor    = darkMode ? grayBlack : green50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: darkMode ? white : carbonBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: appBarTitle(
          text: 'About CropGuard',
          color: darkMode ? white : carbonBlack,
          size: 20,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- App Icon Hero ---
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: brandGreen.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: brandGreen, size: 52),
            ),
            const SizedBox(height: 16),
            heading(
              text: 'CropGuard',
              color: textColor,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            cardSubtitle(
              text: 'Cotton Disease Detection',
              color: brandGreen,
              align: TextAlign.center,
            ),
            const SizedBox(height: 4),
            cardSubtitle(
              text: 'Version 1.0.0',
              color: subtitleColor,
              align: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // --- Mission Card ---
            _InfoCard(
              darkMode: darkMode,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.track_changes_rounded,
              iconColor: primaryBlue,
              title: 'Our Mission',
              body:
              'CropGuard empowers farmers with AI-powered cotton disease detection. '
                  'Snap a photo of your crop and get instant diagnosis — no internet required.',
            ),
            const SizedBox(height: 16),

            // --- What We Detect ---
            _InfoCard(
              darkMode: darkMode,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.search_rounded,
              iconColor: warningYellow,
              title: 'Detectable Diseases',
              body: '',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DiseaseChip(label: 'Bacterial Blight',  color: errorRed,     darkMode: darkMode),
                  _DiseaseChip(label: 'Curl Virus',        color: warningYellow, darkMode: darkMode),
                  _DiseaseChip(label: 'Fusarium Wilt',     color: lightOrange,   darkMode: darkMode),
                  _DiseaseChip(label: 'Healthy Cotton ✓',  color: successGreen,  darkMode: darkMode),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Tech Stack ---
            _InfoCard(
              darkMode: darkMode,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.memory_rounded,
              iconColor: brandGreen,
              title: 'Powered By',
              body:
              'EfficientNetB0 transfer learning model trained on cotton disease datasets. '
                  'Runs fully on-device via TensorFlow Lite — your crop data never leaves your phone.',
            ),
            const SizedBox(height: 16),

            // --- Developer ---
            _InfoCard(
              darkMode: darkMode,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.code_rounded,
              iconColor: purple,
              title: 'Developer',
              body: 'Built with Flutter & Dart.\nFor support or feedback, reach us at:\n225179@aack.au.edu.pk',
            ),
            const SizedBox(height: 32),

            // --- Footer ---
            bodyText(
              text: '© 2026 CropGuard. All rights reserved.',
              color: subtitleColor,
              align: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Info Card ───────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool darkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? child;

  const _InfoCard({
    required this.darkMode,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              heading(text: title, color: textColor, align: TextAlign.left),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 12),
            bodyText(text: body, color: subtitleColor),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

// ─── Disease Chip ─────────────────────────────────────────────────────────────

class _DiseaseChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool darkMode;

  const _DiseaseChip({
    required this.label,
    required this.color,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          cardSubtitle(text: label, color: color, align: TextAlign.left),
        ],
      ),
    );
  }
}