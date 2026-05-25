import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  // Track which section is expanded
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final darkMode = Provider.of<DarkModeProvider>(context).isDarkMode;

    final backgroundColor = darkMode ? darkBlack : white;
    final appBarColor    = darkMode ? lightGrayBlack : white;
    final textColor      = darkMode ? white : carbonBlack;
    final subtitleColor  = darkMode ? lightGray : mediumGray;
    final cardColor      = darkMode ? lightGrayBlack : cardBg;
    final accentColor    = darkMode ? green300 : brandGreen;
    final dividerColor   = darkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    final sections = _termsSections();

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
          text: 'Terms of Service',
          color: darkMode ? white : carbonBlack,
          size: 20,
        ),
      ),
      body: Column(
        children: [
          // --- Header ---
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
                    color: primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cardSubtitle(
                        text:
                        'By using CropGuard, you agree to these terms.',
                        color: subtitleColor,
                        align: TextAlign.left,
                      ),
                      cardSubtitle(
                        text: 'Effective: April 30, 2026',
                        color: accentColor,
                        align: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // --- Expandable Terms List ---
          Expanded(
            child: ListView.separated(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final section = sections[index];
                final isExpanded = _expanded.contains(index);

                return _ExpandableTermCard(
                  darkMode: darkMode,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  accentColor: accentColor,
                  number: '${index + 1}',
                  title: section['title']!,
                  body: section['body']!,
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expanded.remove(index);
                      } else {
                        _expanded.add(index);
                      }
                    });
                  },
                );
              },
            ),
          ),

          // --- Accept Footer ---
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: appBarColor,
              border: Border(
                  top: BorderSide(color: dividerColor, width: 1)),
            ),
            child: Column(
              children: [
                bodyText(
                  text:
                  'Questions? Contact us at 225179@aack.au.edu.pk',
                  color: subtitleColor,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expandable Card ─────────────────────────────────────────────────────────

class _ExpandableTermCard extends StatelessWidget {
  final bool darkMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String number;
  final String title;
  final String body;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ExpandableTermCard({
    required this.darkMode,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.number,
    required this.title,
    required this.body,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? accentColor.withOpacity(0.35)
              : darkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        number,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: heading(
                          text: title,
                          color: textColor,
                          align: TextAlign.left),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                // Expandable body
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: bodyText(text: body, color: subtitleColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

List<Map<String, String>> _termsSections() => [
  {
    'title': 'Acceptance of Terms',
    'body':
    'By downloading or using CropGuard, you agree to be bound by these Terms of Service. '
        'If you do not agree, do not use the application.',
  },
  {
    'title': 'Use of the App',
    'body':
    'CropGuard is provided for informational and agricultural assistance purposes only. '
        'You agree to use the app only for lawful purposes and in accordance with these terms.',
  },
  {
    'title': 'Medical / Agricultural Disclaimer',
    'body':
    'Disease detection results are AI-generated and are not a substitute for professional agronomist advice. '
        'Always consult a qualified expert before taking action on your crops based on app results.',
  },
  {
    'title': 'Intellectual Property',
    'body':
    'All content, UI, ML models, and branding within CropGuard are the intellectual property of the developers. '
        'You may not reproduce, distribute, or create derivative works without written permission.',
  },
  {
    'title': 'Limitation of Liability',
    'body':
    'CropGuard is provided "as is" without warranties of any kind. '
        'We are not liable for any agricultural losses, crop damage, or financial harm resulting from use of this app.',
  },
  {
    'title': 'Prohibited Activities',
    'body':
    'You may not reverse-engineer, decompile, or attempt to extract the ML model from this application. '
        'You may not use the app to create competing products without prior written consent.',
  },
  {
    'title': 'Termination',
    'body':
    'We reserve the right to discontinue the app or terminate access for any user who violates these terms '
        'without prior notice.',
  },
  {
    'title': 'Changes to Terms',
    'body':
    'We may revise these Terms at any time. Continued use of the app after changes are posted '
        'constitutes your acceptance of the revised terms.',
  },
];