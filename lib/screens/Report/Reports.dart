// lib/screens/History/history_screen.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Detection history list
// Shows all saved reports. Each tile shows:
//   • Disease name + severity badge
//   • Confidence %
//   • City + temperature at time of detection
//   • Formatted date/time
// Tapping a tile opens ReportDetailScreen.
// ─────────────────────────────────────────────────────────────

import 'package:cotton_disease/screens/Report/reportPreviewScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;
    final user = FirebaseAuth.instance.currentUser;

    final bg = isDark ? darkBlack : const Color(0xFFF4F6F4);
    final appBarBg = isDark ? lightGrayBlack : white;
    final textColor = isDark ? white : carbonBlack;

    if (user == null) {
      return _buildNotLoggedIn(isDark, textColor);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        title: Text(
          'Detection Reports',
          style: GoogleFonts.saira(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('detections')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandGreen),
            );
          }

          if (snapshot.hasError) {
            return _buildError(isDark, textColor, snapshot.error.toString());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmpty(isDark, textColor);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _HistoryTile(
                data: data,
                docId: docId,
                isDark: isDark,
                textColor: textColor,
                userId: user.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedIn(bool isDark, Color textColor) {
    return Scaffold(
      backgroundColor: isDark ? darkBlack : const Color(0xFFF4F6F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 56, color: mediumGray.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text('Login Required',
                style: GoogleFonts.saira(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 8),
            Text('Sign in to view your detection history.',
                style:
                GoogleFonts.montserrat(fontSize: 13, color: mediumGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: mediumGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Reports Yet',
              style: GoogleFonts.saira(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const SizedBox(height: 8),
          Text('Scan a cotton leaf to create your first report.',
              style: GoogleFonts.montserrat(fontSize: 13, color: mediumGray),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark, Color textColor, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: errorRed),
            const SizedBox(height: 16),
            Text('Failed to load history',
                style: GoogleFonts.saira(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 8),
            Text(error,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: mediumGray, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Single history tile ───────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isDark;
  final Color textColor;
  final String userId;

  const _HistoryTile({
    required this.data,
    required this.docId,
    required this.isDark,
    required this.textColor,
    required this.userId,
  });

  Color get _severityColor {
    final isHealthy = data['isHealthy'] as bool? ?? false;
    if (isHealthy) return brandGreen;
    switch (data['severity'] as String? ?? '') {
      case 'High':
        return errorRed;
      case 'Moderate':
        return warningYellow;
      default:
        return const Color(0xFFEAB308);
    }
  }

  IconData get _severityIcon {
    final isHealthy = data['isHealthy'] as bool? ?? false;
    if (isHealthy) return Icons.check_circle_rounded;
    switch (data['severity'] as String? ?? '') {
      case 'High':
        return Icons.warning_rounded;
      case 'Moderate':
        return Icons.info_rounded;
      default:
        return Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return DateFormat('dd MMM yyyy  •  HH:mm').format(dt);
    } catch (_) {
      return 'Unknown date';
    }
  }

  String get _weatherLine {
    final city = data['weatherCity'] as String?;
    final temp = data['weatherTemp'] as num?;
    final main = data['weatherMain'] as String?;

    if (city == null && temp == null) return '';

    final parts = <String>[];
    if (city != null && city.isNotEmpty && city != 'Unknown') {
      parts.add(city);
    }
    if (temp != null) {
      parts.add('${temp.toStringAsFixed(1)}°C');
    }
    if (main != null && main.isNotEmpty && main != 'Unknown') {
      parts.add(main);
    }
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _severityColor;
    final displayName =
        data['displayName'] as String? ?? 'Unknown Disease';
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
    final severity = data['severity'] as String? ?? '—';
    final timestamp = data['timestamp'];
    final weather = _weatherLine;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(
              data: data,
              docId: docId,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? lightGrayBlack : white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sColor.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ─────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_severityIcon, color: sColor, size: 22),
            ),
            const SizedBox(width: 12),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name
                  Text(
                    displayName,
                    style: GoogleFonts.saira(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Confidence + severity
                  Row(
                    children: [
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}% confidence',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: mediumGray,
                            fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: sColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          severity,
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: sColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(timestamp),
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: mediumGray),
                      ),
                    ],
                  ),

                  // Weather line (city + temp) — only if available
                  if (weather.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined,
                            size: 11, color: mediumGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            weather,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: mediumGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Chevron ──────────────────────────────────────
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: mediumGray.withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }
}