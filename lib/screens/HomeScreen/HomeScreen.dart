// lib/screens/Home/home_screen.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Home Screen
// Real data:
//   • Disease stats (Healthy / Warning / Disease %) from Firestore
//   • Top 2 latest detection reports from Firestore
//   • Live weather (city + temp + condition) from WeatherProvider
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'package:cotton_disease/screens/HomeScreen/tips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../ Detection Result Screen/detection_result_screen.dart';
import '../../Provider/ThemeProvider.dart';
import '../../Provider/WeatherProvider.dart';
import '../../utils/Camera.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';
import '../Report/Reports.dart';
import '../Report/reportPreviewScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    // Trigger weather fetch on open — non-blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;

    final Color bgColor = isDark ? darkBlack : screenBg;
    final Color cardColor = isDark ? lightGrayBlack : cardBg;
    final Color textColor = isDark ? white : carbonBlack;
    final Color secondaryText = isDark ? Colors.white70 : mediumGray;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      "assets/images/cotton_field.jpg",
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child:
                          appBarTitle(text: "Crop Guard", color: white),
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) => Opacity(
                            opacity: _animation.value,
                            child: bodyText(
                              text:
                              "Scan Your Cotton Leaves Now – AI Detects Diseases to Save Your Harvest",
                              color: white,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              maxWidth:
                              MediaQuery.of(context).size.width * 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Hero scan button ─────────────────────────────
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [green100, brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 120,
                    child: Image.asset(
                      'assets/images/verified_cotton.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: carbonBlack,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      onPressed: () async {
                        final imagePath = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraUIScreen(),
                          ),
                        );

                        if (imagePath != null && mounted) {
                          final file = File(imagePath);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetectionResultScreen(imageFile: file),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, color: white, size: 20),
                          const SizedBox(width: 8),
                          buttonText(text: "Start Scan", color: white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Disease stats — real Firestore data ──────────
            if (user != null)
              _RealStatsRow(userId: user.uid)
            else
              _StaticStatsRow(),
            const SizedBox(height: 20),

            // ── Tips ─────────────────────────────────────────
            _HomeTipsSection(isDark: isDark, textColor: textColor,),
            const SizedBox(height: 20),

            // ── My Reports — real Firestore top-2 ───────────
            if (user != null)
              _RealReportsSection(
                  userId: user.uid, isDark: isDark, textColor: textColor)
            else
              _EmptyReportsSection(isDark: isDark, textColor: textColor),
            const SizedBox(height: 20),

            // ── Weather — real from WeatherProvider ──────────
            _WeatherWidget(isDark: isDark, textColor: textColor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────
// DROP THIS INTO home_screen.dart
//
// 1. Replace the static Tips Container(...) block with:
//       _HomeTipsSection(isDark: isDark, textColor: textColor)
//
// 2. Add this import at the top of home_screen.dart:
//       import '../Tips/tips_screen.dart';
//       import '../../data/tips_data.dart';
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Home Tips Section — shows first 3 tips as preview rows
// ─────────────────────────────────────────────────────────────
class _HomeTipsSection extends StatelessWidget {
  final bool isDark;
  final Color textColor;

  const _HomeTipsSection({required this.isDark, required this.textColor});

  Color _accentFor(TipCategory cat) {
    switch (cat) {
      case TipCategory.scanning:
        return primaryBlue;
      case TipCategory.watering:
        return const Color(0xff29B6F6);
      case TipCategory.treatment:
        return errorRed;
      case TipCategory.prevention:
        return brandGreen;
      case TipCategory.harvest:
        return warningYellow;
      case TipCategory.soil:
        return const Color(0xff8D6E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDark ? lightGrayBlack : cardBg;
    final Color subText = isDark ? Colors.white60 : mediumGray;

    // Show first 3 tips as preview
    final previewTips = allTips.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              heading(text: "Tips", color: brandGreen),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TipsScreen()),
                ),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: brandGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: brandGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview tip rows
          ...List.generate(previewTips.length, (i) {
            final tip = previewTips[i];
            final accent = _accentFor(tip.category);
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip.icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: GoogleFonts.saira(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            tip.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: subText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (i < previewTips.length - 1)
                  Divider(
                    height: 20,
                    thickness: 0.5,
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Footer count
          Center(
            child: Text(
              '${allTips.length} tips available — tap View All',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: subText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────
// REAL Stats Row — streams Firestore and computes %
// ─────────────────────────────────────────────────────────────
class _RealStatsRow extends StatelessWidget {
  final String userId;
  const _RealStatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('detections')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                  3,
                      (_) => Expanded(
                    child: Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: brandGreen),
                        ),
                      ),
                    ),
                  )),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;

        if (total == 0) {
          return _buildStatCards(healthy: 0, warning: 0, disease: 0,
              hPct: '—', wPct: '—', dPct: '—');
        }

        int healthyCount = 0;
        int moderateCount = 0;
        int highCount = 0;

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final isHealthy = d['isHealthy'] as bool? ?? false;
          final severity = d['severity'] as String? ?? '';

          if (isHealthy) {
            healthyCount++;
          } else if (severity == 'High') {
            highCount++;
          } else {
            moderateCount++;
          }
        }

        String pct(int count) =>
            '${(count / total * 100).round()}%';

        return _buildStatCards(
          healthy: healthyCount,
          warning: moderateCount,
          disease: highCount,
          hPct: pct(healthyCount),
          wPct: pct(moderateCount),
          dPct: pct(highCount),
        );
      },
    );
  }

  Widget _buildStatCards({
    required int healthy,
    required int warning,
    required int disease,
    required String hPct,
    required String wPct,
    required String dPct,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatusCard(title: "Healthy", color: successGreen, percentage: hPct),
          _StatusCard(title: "Warning", color: warningYellow, percentage: wPct),
          _StatusCard(title: "Disease", color: errorRed, percentage: dPct),
        ],
      ),
    );
  }
}

class _StaticStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _StatusCard(title: "Healthy", color: successGreen, percentage: '—'),
          _StatusCard(title: "Warning", color: warningYellow, percentage: '—'),
          _StatusCard(title: "Disease", color: errorRed, percentage: '—'),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final Color color;
  final String percentage;

  const _StatusCard({
    required this.title,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == "Healthy"
                  ? Icons.check_circle
                  : title == "Warning"
                  ? Icons.warning
                  : Icons.error,
              color: white,
              size: 30,
            ),
            const SizedBox(height: 8),
            buttonText(text: title, color: white),
            const SizedBox(height: 4),
            cardSubtitle(text: percentage, color: white),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REAL Reports Section — top 2 latest from Firestore
// ─────────────────────────────────────────────────────────────
class _RealReportsSection extends StatelessWidget {
  final String userId;
  final bool isDark;
  final Color textColor;

  const _RealReportsSection({
    required this.userId,
    required this.isDark,
    required this.textColor,
  });

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      return DateFormat('MMM d').format((timestamp as Timestamp).toDate());
    } catch (_) {
      return '';
    }
  }

  IconData _icon(Map<String, dynamic> data) {
    final isHealthy = data['isHealthy'] as bool? ?? false;
    if (isHealthy) return Icons.check_circle_outline_rounded;
    final severity = data['severity'] as String? ?? '';
    return severity == 'High'
        ? Icons.report_problem_rounded
        : Icons.info_outline_rounded;
  }

  Color _iconColor(Map<String, dynamic> data) {
    final isHealthy = data['isHealthy'] as bool? ?? false;
    if (isHealthy) return white;
    final severity = data['severity'] as String? ?? '';
    return white;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('detections')
          .orderBy('timestamp', descending: true)
          .limit(2)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [green100, brandGreen.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(text: "My Reports", color: white),
              const SizedBox(height: 10),

              if (!snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: white),
                    ),
                  ),
                )
              else if (docs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: bodyText(
                        text: 'No reports yet. Scan a leaf to start.',
                        color: Colors.white70),
                  ),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final displayName =
                      data['displayName'] as String? ?? 'Unknown';
                  final isHealthy = data['isHealthy'] as bool? ?? false;
                  final dateStr = _formatDate(data['timestamp']);
                  final subtitle = isHealthy
                      ? 'No issues detected'
                      : '${data['severity'] ?? ''} severity — treatment needed';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                    Icon(_icon(data), color: _iconColor(data), size: 30),
                    title: bodyText(
                      text: dateStr.isNotEmpty
                          ? '$displayName – $dateStr'
                          : displayName,
                      color: white,
                    ),
                    subtitle: bodyText(text: subtitle, color: Colors.white70),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: white, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(
                            data: data,
                            docId: doc.id,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  );
                }),

              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HistoryScreen()),
                  );
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: buttonText(
                      text: "View All Reports",
                      color: white,
                      weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyReportsSection extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  const _EmptyReportsSection(
      {required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [green100, brandGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(text: "My Reports", color: white),
          const SizedBox(height: 12),
          Center(
            child: bodyText(
                text: 'Sign in to view your reports.', color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REAL Weather Widget — from WeatherProvider
// Shows: icon + temp, city name, condition, date/time
// ─────────────────────────────────────────────────────────────
class _WeatherWidget extends StatelessWidget {
  final bool isDark;
  final Color textColor;

  const _WeatherWidget({required this.isDark, required this.textColor});

  IconData _weatherIcon(String? main) {
    switch (main?.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return Icons.umbrella_rounded;
      case 'thunderstorm':
        return Icons.bolt_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_outlined;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  Color _weatherIconColor(String? main) {
    switch (main?.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return const Color(0xFF60A5FA); // blue
      case 'snow':
        return const Color(0xFFBAE6FD);
      case 'clouds':
        return mediumGray;
      default:
        return lightOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final cardColor = isDark ? lightGrayBlack : cardBg;
    final secondaryText = isDark ? Colors.white70 : mediumGray;
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a, MMM d').format(now);

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: () {
        // ── Loading ───────────────────────────────────────
        if (weather.isLoading) {
          return Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: brandGreen),
              ),
              const SizedBox(width: 12),
              bodyText(text: 'Fetching weather...', color: secondaryText),
            ],
          );
        }

        // ── Error ─────────────────────────────────────────
        if (weather.hasError || !weather.hasData || weather.current == null) {
          return Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: lightOrange, size: 30),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bodyText(text: 'Weather unavailable', color: textColor),
                  bodyText(text: timeStr, color: secondaryText),
                ],
              ),
            ],
          );
        }

        // ── Data ──────────────────────────────────────────
        final current = weather.current!;
        final tempC = current.temperature?.celsius;
        final weatherMain = current.weatherMain;
        final city = current.areaName ?? current.country ?? '';
        final tempStr = tempC != null
            ? '${tempC.toStringAsFixed(1)}°C'
            : '—';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _weatherIcon(weatherMain),
                  color: _weatherIconColor(weatherMain),
                  size: 34,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temperature — large and prominent
                    Text(
                      tempStr,
                      style: GoogleFonts.saira(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    // City name
                    if (city.isNotEmpty)
                      Text(
                        city,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    // Condition (Sunny, Cloudy, etc.)
                    if (weatherMain != null)
                      Text(
                        weatherMain,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: secondaryText,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Date + time on right
            Text(
              timeStr,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: secondaryText,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        );
      }(),
    );
  }
}