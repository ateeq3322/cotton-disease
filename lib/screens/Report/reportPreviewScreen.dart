// lib/screens/History/report_detail_screen.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Full report detail screen
// Displays all stored fields for a saved detection:
//   • Disease name, confidence, severity
//   • Treatment recommendation
//   • City + temperature + weather condition at detection time
//   • GPS coordinates (if stored)
//   • Date/time of detection
// Per FYP-2 SRS: result screen must show city and temperature
// captured at the moment of detection.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Provider/ThemeProvider.dart';
import '../../utils/constants/colors.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const ReportDetailScreen({
    super.key,
    required this.data,
    required this.docId,
    required this.userId,
  });

  // ── Helpers ───────────────────────────────────────────────
  Color _severityColor(bool isHealthy, String severity) {
    if (isHealthy) return brandGreen;
    switch (severity) {
      case 'High':
        return errorRed;
      case 'Moderate':
        return warningYellow;
      default:
        return const Color(0xFFEAB308);
    }
  }

  IconData _severityIcon(bool isHealthy, String severity) {
    if (isHealthy) return Icons.check_circle_rounded;
    switch (severity) {
      case 'High':
        return Icons.warning_rounded;
      case 'Moderate':
        return Icons.info_rounded;
      default:
        return Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return DateFormat('EEEE, dd MMMM yyyy  •  HH:mm').format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _deleteReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content:
        const Text('This report will be permanently deleted from history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: errorRed))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('detections')
          .doc(docId)
          .delete();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;
    final bg = isDark ? darkBlack : const Color(0xFFF4F6F4);
    final appBarBg = isDark ? lightGrayBlack : white;
    final textColor = isDark ? white : carbonBlack;

    // ── Extract stored fields ─────────────────────────────
    final bool isHealthy = data['isHealthy'] as bool? ?? false;
    final String displayName =
        data['displayName'] as String? ?? 'Unknown';
    final double confidence =
        (data['confidence'] as num?)?.toDouble() ?? 0.0;
    final String severity = data['severity'] as String? ?? '—';
    final String treatment =
        data['treatment'] as String? ?? 'No treatment information available.';
    final dynamic timestamp = data['timestamp'];

    // Weather
    final String? weatherCity = data['weatherCity'] as String?;
    final num? weatherTemp = data['weatherTemp'] as num?;
    final String? weatherMain = data['weatherMain'] as String?;
    final num? weatherHumidity = data['weatherHumidity'] as num?;
    final num? weatherWindSpeed = data['weatherWindSpeed'] as num?;
    final bool hasWeather =
        weatherCity != null || weatherTemp != null;

    // GPS
    final num? lat = data['latitude'] as num?;
    final num? lng = data['longitude'] as num?;
    final bool hasGps = lat != null && lng != null;

    final sColor = _severityColor(isHealthy, severity);
    final sIcon = _severityIcon(isHealthy, severity);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        title: Text(
          'Detection Report',
          style: GoogleFonts.saira(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: errorRed, size: 22),
            tooltip: 'Delete report',
            onPressed: () => _deleteReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Result card ─────────────────────────────
            _SectionCard(
              isDark: isDark,
              borderColor: sColor,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(sIcon, color: sColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.saira(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${(confidence * 100).toStringAsFixed(1)}% confidence',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: mediumGray,
                                  fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(width: 8),
                            _SeverityBadge(severity: severity, color: sColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 2. Confidence bar ──────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Model Confidence',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: mediumGray,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.saira(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: isDark
                          ? const Color(0xFF2A3530)
                          : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation(sColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 3. Detection time ──────────────────────────
            _InfoRow(
              isDark: isDark,
              icon: Icons.access_time_rounded,
              label: 'Detection Time',
              value: _formatDate(timestamp),
              textColor: textColor,
            ),

            const SizedBox(height: 12),

            // ── 4. Field conditions (weather) ──────────────
            if (hasWeather) ...[
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            size: 16, color: warningYellow),
                        const SizedBox(width: 8),
                        Text(
                          'Field Conditions at Detection',
                          style: GoogleFonts.saira(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // City
                    if (weatherCity != null &&
                        weatherCity.isNotEmpty &&
                        weatherCity != 'Unknown')
                      _WeatherDetailRow(
                        icon: Icons.location_city_rounded,
                        label: 'Location',
                        value: weatherCity,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    // Temperature
                    if (weatherTemp != null)
                      _WeatherDetailRow(
                        icon: Icons.thermostat_rounded,
                        label: 'Temperature',
                        value: '${weatherTemp.toStringAsFixed(1)}°C',
                        isDark: isDark,
                        textColor: textColor,
                        valueColor: _tempColor(weatherTemp.toDouble()),
                      ),
                    // Weather condition
                    if (weatherMain != null &&
                        weatherMain.isNotEmpty &&
                        weatherMain != 'Unknown')
                      _WeatherDetailRow(
                        icon: Icons.cloud_outlined,
                        label: 'Condition',
                        value: weatherMain,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    // Humidity
                    if (weatherHumidity != null)
                      _WeatherDetailRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Humidity',
                        value: '${weatherHumidity.toStringAsFixed(0)}%',
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    // Wind speed
                    if (weatherWindSpeed != null)
                      _WeatherDetailRow(
                        icon: Icons.air_rounded,
                        label: 'Wind Speed',
                        value: '${weatherWindSpeed.toStringAsFixed(1)} m/s',
                        isDark: isDark,
                        textColor: textColor,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── 5. GPS ─────────────────────────────────────
            if (hasGps) ...[
              _InfoRow(
                isDark: isDark,
                icon: Icons.my_location_rounded,
                label: 'GPS Coordinates',
                value:
                '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
                textColor: textColor,
              ),
              const SizedBox(height: 12),
            ],

            // ── 6. Treatment ───────────────────────────────
            _SectionCard(
              isDark: isDark,
              borderColor: isHealthy ? brandGreen : warningYellow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHealthy
                            ? Icons.eco_rounded
                            : Icons.medication_liquid_rounded,
                        color: isHealthy ? brandGreen : warningYellow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended Action',
                        style: GoogleFonts.saira(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isHealthy ? brandGreen : warningYellow,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    treatment,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      height: 1.7,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 7. Report metadata ─────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: mediumGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For agricultural guidance only. '
                          'Consult an agronomist or plant pathologist for '
                          'confirmed diagnosis and treatment decisions.',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: mediumGray, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tempColor(double temp) {
    if (temp >= 35) return errorRed;
    if (temp >= 25) return warningYellow;
    return brandGreen;
  }
}

// ── Reusable widgets ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final Color? borderColor;

  const _SectionCard({
    required this.isDark,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? lightGrayBlack : white,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null
            ? Border.all(color: borderColor!.withOpacity(0.22), width: 1.2)
            : Border.all(
          color: isDark
              ? const Color(0xFF2E3830)
              : const Color(0xFFE5EAE5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _InfoRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: mediumGray,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: textColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color textColor;
  final Color? valueColor;

  const _WeatherDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.textColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: mediumGray),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.montserrat(
                fontSize: 12,
                color: mediumGray,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: valueColor ?? textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity,
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}