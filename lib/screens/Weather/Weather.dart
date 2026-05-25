import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Provider/ThemeProvider.dart';
import '../../Provider/WeatherProvider.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame so context is ready for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = context.watch<DarkModeProvider>().isDarkMode;
    final weather     = context.watch<WeatherProvider>();

    final bgColor     = isDark ? darkBlack      : screenBg;
    final appBarColor = isDark ? lightGrayBlack  : white;
    final textColor   = isDark ? white           : grayBlack;
    final cardColor   = isDark ? lightGrayBlack  : white;
    final subColor    = isDark ? lightGray       : mediumGray;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: appBarTitle(
          text: "Weather Insights",
          color: isDark ? white : lightGrayBlack,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? white : grayBlack),
            onPressed: () =>
                context.read<WeatherProvider>().fetchAll(forceRefresh: true),
          ),
        ],
      ),
      body: _buildBody(
        context: context,
        weather: weather,
        isDark: isDark,
        bgColor: bgColor,
        textColor: textColor,
        cardColor: cardColor,
        subColor: subColor,
      ),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────────────

  Widget _buildBody({
    required BuildContext context,
    required WeatherProvider weather,
    required bool isDark,
    required Color bgColor,
    required Color textColor,
    required Color cardColor,
    required Color subColor,
  }) {
    if (weather.isLoading) {
      return _ShimmerWeather(isDark: isDark, bgColor: bgColor, cardColor: cardColor);
    }

    if (weather.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: subColor, size: 48),
              const SizedBox(height: 16),
              bodyText(
                text: weather.errorMessage ?? "Something went wrong.",
                color: textColor,
                align: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<WeatherProvider>().fetchAll(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: buttonText(text: "Retry"),
                style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
              ),
            ],
          ),
        ),
      );
    }

    if (!weather.hasData || weather.current == null) {
      return Center(child: bodyText(text: "No data", color: textColor));
    }

    return _WeatherContent(
      isDark: isDark,
      textColor: textColor,
      cardColor: cardColor,
      subColor: subColor,
      provider: weather,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHIMMER
// ═══════════════════════════════════════════════════════════════════════════════

class _ShimmerWeather extends StatefulWidget {
  final bool isDark;
  final Color bgColor;
  final Color cardColor;

  const _ShimmerWeather({
    required this.isDark,
    required this.bgColor,
    required this.cardColor,
  });

  @override
  State<_ShimmerWeather> createState() => _ShimmerWeatherState();
}

class _ShimmerWeatherState extends State<_ShimmerWeather>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final shimmerBase  = widget.isDark ? const Color(0xff2a2e2e) : const Color(0xffE0E0E0);
        final shimmerShine = widget.isDark ? const Color(0xff3a3e3e) : const Color(0xffF5F5F5);

        final gradient = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end:   Alignment(_anim.value + 1, 0),
          colors: [shimmerBase, shimmerShine, shimmerBase],
        );

        Widget box(double w, double h, {double radius = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              box(double.infinity, 220, radius: 20),
              const SizedBox(height: 20),
              // Stat row 1
              Row(children: [
                Expanded(child: box(double.infinity, 90)),
                const SizedBox(width: 10),
                Expanded(child: box(double.infinity, 90)),
              ]),
              const SizedBox(height: 10),
              // Stat row 2
              Row(children: [
                Expanded(child: box(double.infinity, 90)),
                const SizedBox(width: 10),
                Expanded(child: box(double.infinity, 90)),
              ]),
              const SizedBox(height: 24),
              box(140, 20, radius: 8),
              const SizedBox(height: 12),
              // Hourly chips
              Row(children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: box(70, 60, radius: 8),
              ))),
              const SizedBox(height: 24),
              box(140, 20, radius: 8),
              const SizedBox(height: 12),
              box(double.infinity, 180, radius: 16),
              const SizedBox(height: 20),
              box(double.infinity, 100, radius: 16),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _WeatherContent extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final Color subColor;
  final WeatherProvider provider;

  const _WeatherContent({
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.subColor,
    required this.provider,
  });

  IconData _weatherIcon(String? main) {
    switch (main?.toLowerCase()) {
      case 'clear':  return Icons.wb_sunny_outlined;
      case 'clouds': return Icons.wb_cloudy_outlined;
      case 'rain':   return Icons.water_drop_outlined;
      case 'snow':   return Icons.ac_unit_outlined;
      default:       return Icons.wb_twilight_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = provider.current!;
    final isRain = cur.weatherDescription?.toLowerCase().contains('rain') ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ── Hero Card ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [lightPink, lightPurple, lightBlue]
                      : [splashBg, onboardingBg, brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _weatherIcon(cur.weatherMain),
                      color: Colors.white24,
                      size: 200,
                    ),
                  ),
                  Column(
                    children: [
                      heading(
                          text: cur.areaName ?? "Unknown",
                          color: white,
                          weight: FontWeight.w400),
                      const SizedBox(height: 10),
                      appBarTitle(
                          text:
                          "${cur.temperature?.celsius?.toStringAsFixed(1) ?? '--'}°C",
                          size: 48,
                          color: white),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_weatherIcon(cur.weatherMain),
                              color: white, size: 22),
                          const SizedBox(width: 6),
                          heading(text: cur.weatherMain ?? '', color: white),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: bodyText(
                          text: isRain
                              ? "⚠️ Rain detected — Water logging risk!"
                              : "Optimal Growth Conditions",
                          color: white,
                          align: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stat Grid ─────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_outlined,
                  label: "Humidity",
                  value: "${cur.humidity?.toStringAsFixed(0) ?? '--'}%",
                  isDark: isDark, cardColor: cardColor,
                  textColor: textColor, subColor: subColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.air,
                  label: "Wind",
                  value: "${cur.windSpeed?.toStringAsFixed(1) ?? '--'} m/s",
                  isDark: isDark, cardColor: cardColor,
                  textColor: textColor, subColor: subColor,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.speed,
                  label: "Pressure",
                  value: "${cur.pressure?.toStringAsFixed(0) ?? '--'} hPa",
                  isDark: isDark, cardColor: cardColor,
                  textColor: textColor, subColor: subColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.thermostat,
                  label: "Feels Like",
                  value:
                  "${cur.tempFeelsLike?.celsius?.toStringAsFixed(0) ?? '--'}°C",
                  isDark: isDark, cardColor: cardColor,
                  textColor: textColor, subColor: subColor,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Hourly ────────────────────────────────────────────────────
            heading(text: "Next 15 Hours", align: TextAlign.start, color: textColor),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.hourlyForecast?.length ?? 0,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final f = provider.hourlyForecast![i];
                  final t = f.date!.toLocal();
                  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
                  final p = t.hour >= 12 ? 'PM' : 'AM';
                  return _HourlyChip(
                    time: "$h $p",
                    icon: _weatherIcon(f.weatherMain),
                    temp:
                    "${f.temperature?.celsius?.toStringAsFixed(1) ?? '--'}°C",
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subColor: subColor,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Daily ─────────────────────────────────────────────────────
            heading(text: "6-Day Forecast", align: TextAlign.start, color: textColor),
            const SizedBox(height: 8),
            if (provider.dailyForecast != null) ...[
              // Today's min/max summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: brandGreen.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      cardSubtitle(text: "Today's Min", color: subColor),
                      const SizedBox(height: 4),
                      appBarTitle(
                        text: provider.dailyForecast!.isNotEmpty
                            ? "${provider.dailyForecast![0]['minTemp'].toStringAsFixed(1)}°C"
                            : "--",
                        color: textColor,
                        weight: FontWeight.bold,
                        size: 22,
                      ),
                    ]),
                    Container(width: 1, height: 40,
                        color: brandGreen.withOpacity(0.3)),
                    Column(children: [
                      cardSubtitle(text: "Today's Max", color: subColor),
                      const SizedBox(height: 4),
                      appBarTitle(
                        text: provider.dailyForecast!.isNotEmpty
                            ? "${provider.dailyForecast![0]['maxTemp'].toStringAsFixed(1)}°C"
                            : "--",
                        color: textColor,
                        weight: FontWeight.bold,
                        size: 22,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Fixed Graph ──────────────────────────────────────────────
              Container(
                height: 200,
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: brandGreen.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    // Day labels row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: provider.dailyForecast!.map((d) {
                        final isToday = (d['date'] as DateTime)
                            .difference(DateTime.now())
                            .inDays == 0;
                        return SizedBox(
                          width: 36,
                          child: cardSubtitle(
                            text: isToday
                                ? 'Today'
                                : DateFormat('EEE').format(d['date']),
                            color: isToday ? brandGreen : subColor,
                            align: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Graph
                    Expanded(
                      child: CustomPaint(
                        painter: _TrendLinePainter(
                          dailyForecast: provider.dailyForecast!,
                          isDark: isDark,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: brandGreen, label: "Max"),
                        const SizedBox(width: 16),
                        _LegendDot(color: brandGreen.withOpacity(0.45), label: "Min"),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Crop Insight ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [darkGreen.withOpacity(0.7), darkBlue2]
                      : [green50, green100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.energy_savings_leaf,
                      color: brandGreen, size: 30),
                  const SizedBox(height: 10),
                  heading(text: "Crop Insight", color: textColor),
                  const SizedBox(height: 6),
                  cardSubtitle(
                    text: isRain
                        ? "Rain conditions may increase disease risk. Monitor closely."
                        : "Conditions are favorable for cotton growth. Maintain regular monitoring.",
                    color: subColor,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool get isRain =>
      provider.current?.weatherDescription?.toLowerCase().contains('rain') ??
          false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBWIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: brandGreen, size: 22),
          const SizedBox(height: 6),
          cardSubtitle(text: label, color: subColor),
          const SizedBox(height: 4),
          appBarTitle(
              text: value, color: textColor, weight: FontWeight.bold, size: 22),
        ],
      ),
    );
  }
}

class _HourlyChip extends StatelessWidget {
  final String time;
  final IconData icon;
  final String temp;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _HourlyChip({
    required this.time,
    required this.icon,
    required this.temp,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandGreen.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          cardSubtitle(text: time, color: subColor, align: TextAlign.center),
          const SizedBox(height: 6),
          Icon(icon, color: brandGreen, size: 20),
          const SizedBox(height: 6),
          // ✅ temp was being ignored before — now displayed
          cardSubtitle(text: temp, color: textColor, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        cardSubtitle(text: label, color: color, align: TextAlign.left),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FIXED GRAPH PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _TrendLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> dailyForecast;
  final bool isDark;

  _TrendLinePainter({required this.dailyForecast, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyForecast.length < 2) return;

    // ── Temperature range ──────────────────────────────────────────────────
    final allTemps = dailyForecast
        .expand((d) => [d['minTemp'] as double, d['maxTemp'] as double])
        .toList();
    final minTemp = allTemps.reduce((a, b) => a < b ? a : b);
    final maxTemp = allTemps.reduce((a, b) => a > b ? a : b);
    final range   = maxTemp - minTemp;

    // Guard: flat line when all temps are equal
    final effectiveRange = range == 0 ? 1.0 : range;

    // ── Layout ────────────────────────────────────────────────────────────
    // Leave vertical padding so dots don't clip at edges
    const double vPad = 16;
    final double drawH = size.height - vPad * 2;

    // X positions evenly spaced, clamped to canvas width
    double xOf(int i) {
      if (dailyForecast.length == 1) return size.width / 2;
      return i * (size.width / (dailyForecast.length - 1));
    }

    double yOf(double temp) {
      // High temp → small y (top); low temp → large y (bottom)
      return vPad + drawH * (1 - (temp - minTemp) / effectiveRange);
    }

    // ── Paints ─────────────────────────────────────────────────────────────
    final maxPaint = Paint()
      ..color       = brandGreen
      ..strokeWidth = 2.5
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final minPaint = Paint()
      ..color       = brandGreen.withOpacity(0.45)
      ..strokeWidth = 2
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final dotMaxPaint = Paint()..color = brandGreen;
    final dotMinPaint = Paint()..color = brandGreen.withOpacity(0.45);

    // ── Build paths ─────────────────────────────────────────────────────────
    final maxPath = Path();
    final minPath = Path();

    for (int i = 0; i < dailyForecast.length; i++) {
      final x      = xOf(i);
      final yMax   = yOf(dailyForecast[i]['maxTemp'] as double);
      final yMin   = yOf(dailyForecast[i]['minTemp'] as double);

      if (i == 0) {
        maxPath.moveTo(x, yMax);
        minPath.moveTo(x, yMin);
      } else {
        // Smooth cubic bezier between points
        final prevX    = xOf(i - 1);
        final prevYMax = yOf(dailyForecast[i - 1]['maxTemp'] as double);
        final prevYMin = yOf(dailyForecast[i - 1]['minTemp'] as double);
        final cpX      = (prevX + x) / 2;

        maxPath.cubicTo(cpX, prevYMax, cpX, yMax, x, yMax);
        minPath.cubicTo(cpX, prevYMin, cpX, yMin, x, yMin);
      }
    }

    canvas.drawPath(maxPath, maxPaint);
    canvas.drawPath(minPath, minPaint);

    // ── Dots + temp labels ─────────────────────────────────────────────────
    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : const Color(0xff424242),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < dailyForecast.length; i++) {
      final x    = xOf(i);
      final yMax = yOf(dailyForecast[i]['maxTemp'] as double);
      final yMin = yOf(dailyForecast[i]['minTemp'] as double);

      // Dots
      canvas.drawCircle(Offset(x, yMax), 4, dotMaxPaint);
      canvas.drawCircle(Offset(x, yMin), 3, dotMinPaint);

      // Max label (above dot)
      _drawLabel(
        canvas,
        "${(dailyForecast[i]['maxTemp'] as double).toStringAsFixed(0)}°",
        Offset(x, yMax - 14),
        textStyle,
      );

      // Min label (below dot)
      _drawLabel(
        canvas,
        "${(dailyForecast[i]['minTemp'] as double).toStringAsFixed(0)}°",
        Offset(x, yMin + 4),
        textStyle.copyWith(color: textStyle.color?.withOpacity(0.6)),
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(_TrendLinePainter old) =>
      old.dailyForecast != dailyForecast || old.isDark != isDark;
}