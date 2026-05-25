import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = Provider.of<DarkModeProvider>(context).isDarkMode;

    final backgroundColor = darkMode ? darkBlack : white;
    final appBarColor    = darkMode ? lightGrayBlack : white;
    final textColor      = darkMode ? white : carbonBlack;
    final subtitleColor  = darkMode ? lightGray : mediumGray;
    final cardColor      = darkMode ? lightGrayBlack : cardBg;
    final dividerColor   = darkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    const lastUpdated = 'Last updated: April 30, 2026';

    final sections = _privacySections();

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
          text: 'Privacy Policy',
          color: darkMode ? white : carbonBlack,
          size: 20,
        ),
      ),
      body: Column(
        children: [
          // --- Header Banner ---
          Container(
            width: double.infinity,
            color: appBarColor,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: brandGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cardSubtitle(
                        text: 'Your data stays on your device.',
                        color: brandGreen,
                        align: TextAlign.left),
                    cardSubtitle(
                        text: lastUpdated,
                        color: subtitleColor,
                        align: TextAlign.left),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // --- Content ---
          Expanded(
            child: ListView.separated(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final section = sections[index];
                return _PolicySection(
                  darkMode: darkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  number: '${index + 1}',
                  title: section['title']!,
                  body: section['body']!,
                );
              },
            ),
          ),

          // --- Footer ---
          Container(
            color: appBarColor,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: bodyText(
              text:
              'If you have questions about this policy, contact us at 225179@aack.au.edu.pk',
              color: subtitleColor,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Widget ───────────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  final bool darkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final String number;
  final String title;
  final String body;

  const _PolicySection({
    required this.darkMode,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: brandGreen,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(text: title, color: textColor, align: TextAlign.left),
                const SizedBox(height: 8),
                bodyText(text: body, color: subtitleColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────────

List<Map<String, String>> _privacySections() => [
  {
    'title': 'Data Collection',
    'body':
    'CropGuard does not collect, transmit, or store any personal data on external servers. '
        'All analysis is performed locally on your device using an on-device TensorFlow Lite model.',
  },
  {
    'title': 'Camera & Image Usage',
    'body':
    'We request camera permission solely to capture crop images for disease detection. '
        'Images are processed in-memory and are never saved to our servers or shared with third parties.',
  },
  {
    'title': 'Storage Permission',
    'body':
    'Storage access is used only to let you pick images from your gallery for analysis. '
        'We do not read, modify, or transmit any other files on your device.',
  },
  {
    'title': 'Analytics & Crash Reporting',
    'body':
    'We may collect anonymised crash reports to improve app stability. '
        'This data contains no personally identifiable information and cannot be linked back to you.',
  },
  {
    'title': 'Third-Party Services',
    'body':
    'CropGuard does not integrate any third-party advertising, tracking, or analytics SDKs. '
        'No data is sold or shared with advertisers.',
  },
  {
    'title': 'Children\'s Privacy',
    'body':
    'This app is not directed at children under 13. '
        'We do not knowingly collect information from children.',
  },
  {
    'title': 'Policy Updates',
    'body':
    'We may update this Privacy Policy occasionally. '
        'Changes will be reflected in the "Last updated" date at the top of this page. '
        'Continued use of the app constitutes acceptance of the updated policy.',
  },
];