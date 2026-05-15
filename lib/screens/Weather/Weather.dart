import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart' as w; // 👈 Alias added here
import '../../Provider/ThemeProvider.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/fonts.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final w.WeatherFactory _wf = w.WeatherFactory(
    "cc038a8adc8b3726463a271f94e326c6",
  );
  w.Weather? _weather;
  List<w.Weather>? _hourlyForecast;
  List<Map<String, dynamic>>? _dailyForecast;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    fetchWeatherForecast();
  }
  IconData _getWeatherIcon(String? weatherMain) {
    switch (weatherMain?.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_outlined;
      case 'clouds':
        return Icons.wb_cloudy_outlined;
      case 'rain':
        return Icons.water_drop_outlined;
      case 'snow':
        return Icons.ac_unit_outlined;
      default:
        return Icons.wb_twilight_rounded;
    }
  }
  Future<void> fetchWeatherForecast() async {
    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch 5-day forecast (3-hour intervals)
      List<w.Weather> forecast = await _wf.fiveDayForecastByLocation(
        position.latitude,
        position.longitude,
      );

      // Process next 5 hours (take first 5 entries, as each is 3 hours apart)
      List<w.Weather> hourlyForecast = forecast.take(5).toList();

      // Process daily forecast (group by day for next 6 days, including today)
      Map<DateTime, List<w.Weather>> dailyForecast = {};
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      for (var weather in forecast) {
        DateTime date = weather.date!;
        DateTime day = DateTime(date.year, date.month, date.day);
        if (day.difference(today).inDays <= 5 && day.difference(today).inDays >= 0) {
          dailyForecast.putIfAbsent(day, () => []).add(weather);
        }
      }

      // Calculate min/max temp for each day
      List<Map<String, dynamic>> dailyData = dailyForecast.entries.map((entry) {
        List<double> temps = entry.value.map((w) => w.temperature!.celsius!).toList();
        return {
          'date': entry.key,
          'minTemp': temps.reduce((a, b) => a < b ? a : b),
          'maxTemp': temps.reduce((a, b) => a > b ? a : b),
        };
      }).toList();

      setState(() {
        _hourlyForecast = hourlyForecast;
        _dailyForecast = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> fetchWeather() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = "Location permission denied.";
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch weather from OpenWeather API
      w.Weather weather = await _wf.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeProvider>(context).isDarkMode;

    final bgColor = isDark ? darkBlack : screenBg;
    final textColor = isDark ? white : grayBlack;
    final cardColor = isDark ? lightGrayBlack : white;
    final subTextColor = isDark ? lightGray : mediumGray;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? lightGrayBlack : white,
        title: appBarTitle(
          text: "Weather Insights",
          color: isDark ? white : lightGrayBlack,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: isDark ? white : grayBlack,
            onPressed: fetchWeather,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : _errorMessage != null
          ? Center(
              child: Text(
                "Error: $_errorMessage",
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
            )
          : _weather == null
          ? Center(
              child: Text(
                "No weather data available",
                style: TextStyle(color: textColor),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // 🌤 Location Card
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.sunny,
                              color: Colors.white24,
                              size: 200,
                            ),
                          ),
                          Column(
                            children: [
                              heading(
                                text: _weather?.areaName ?? "Unknown",
                                color: white,
                                weight: FontWeight.w400,
                              ),
                              const SizedBox(height: 10),
                              appBarTitle(
                                text:
                                    "${_weather?.temperature?.celsius?.toStringAsFixed(1) ?? '--'}°C",
                                size: 48,
                                color: white,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wb_sunny, color: white, size: 24),
                                  const SizedBox(width: 5),
                                  heading(
                                    text: _weather?.weatherMain ?? "Unknown",
                                    color: white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: bodyText(
                                  text:
                                      (_weather?.weatherDescription
                                              ?.toLowerCase()
                                              .contains("rain") ??
                                          false)
                                      ? "Rain detected — Water logging risk!"
                                      : "Crop Health: Optimal Growth Conditions",
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

                    // 🌡 Weather Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.water_drop_outlined,
                            label: "Humidity",
                            value:
                                "${_weather?.humidity?.toStringAsFixed(0) ?? '--'}%",
                            color: brandGreen,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.air,
                            label: "Wind",
                            value:
                                "${_weather?.windSpeed?.toStringAsFixed(1) ?? '--'} m/s",
                            color: brandGreen,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.speed,
                            label: "Pressure",
                            value:
                                "${_weather?.pressure?.toStringAsFixed(0) ?? '--'} hPa",
                            color: brandGreen,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.thermostat,
                            label: "Feels Like",
                            value:
                                "${_weather?.tempFeelsLike?.celsius?.toStringAsFixed(0) ?? '--'}°C",
                            color: brandGreen,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    // 🕒 Hourly Forecast
                    // 🕒 Hourly Forecast (Next 5 Hours)
                    heading(
                      text: "Next 5 Hours Forecast",
                      align: TextAlign.start,
                      color: textColor,
                    ),
                    const SizedBox(height: 10),
                    _hourlyForecast == null
                        ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                        : SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _hourlyForecast!.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final forecast = _hourlyForecast![index];
                          final time = forecast.date!.toLocal();
                          final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
                          final period = time.hour >= 12 ? 'PM' : 'AM';
                          return _buildHourlyItem(
                            "$hour $period",
                            _getWeatherIcon(forecast.weatherMain),
                            isDark,
                            "${forecast.temperature?.celsius?.toStringAsFixed(1) ?? '--'}°C",
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📊 Weekly Trends
                    // 📅 Daily Forecast (Next 6 Days)
                    heading(
                      text: "Next 6 Days Forecast",
                      align: TextAlign.start,
                      color: textColor,
                    ),
                    const SizedBox(height: 5),
                    bodyText(
                      text: "Min and Max temperatures for the next 6 days",
                      align: TextAlign.center,
                      color: subTextColor,
                    ),
                    const SizedBox(height: 10),
                    _dailyForecast == null
                        ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                        : Column(
                      children: [
                        // Current Day Max/Min
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: brandGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  cardSubtitle(text: "Today's Min", color: subTextColor),
                                  appBarTitle(
                                    text: _dailyForecast!.isNotEmpty
                                        ? "${_dailyForecast![0]['minTemp'].toStringAsFixed(1)}°C"
                                        : "--",
                                    color: textColor,
                                    weight: FontWeight.bold,
                                    size: 20,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  cardSubtitle(text: "Today's Max", color: subTextColor),
                                  appBarTitle(
                                    text: _dailyForecast!.isNotEmpty
                                        ? "${_dailyForecast![0]['maxTemp'].toStringAsFixed(1)}°C"
                                        : "--",
                                    color: textColor,
                                    weight: FontWeight.bold,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Trend Line Chart
                        Container(
                          height: 150,
                          child: CustomPaint(
                            painter: DailyTrendLinePainter(dailyForecast: _dailyForecast!),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 20,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: _dailyForecast!.map((day) {
                                      return cardSubtitle(
                                        text: DateFormat('EEE').format(day['date']),
                                        color: textColor,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 🌿 Crop Insight
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.energy_savings_leaf,
                            color: brandGreen,
                            size: 30,
                          ),
                          const SizedBox(height: 10),
                          heading(
                            text: "Optimal Growth Conditions",
                            color: textColor,
                          ),
                          const SizedBox(height: 5),
                          cardSubtitle(
                            text:
                                "The current weather is highly favorable for crop growth. Maintain monitoring.",
                            color: subTextColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildHourlyItem(String time, IconData icon, bool isDark, String temp) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? lightGrayBlack : white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brandGreen.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          cardSubtitle(text: time, color: isDark ? white : grayBlack),
          const SizedBox(height: 5),
          Icon(icon, color: brandGreen, size: 24),
        ],
      ),
    );
  }
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          cardSubtitle(text: label, color: subTextColor),
          appBarTitle(
            text: value,
            color: textColor,
            weight: FontWeight.bold,
            size: 24,
          ),
        ],
      ),
    );
  }

}

class DailyTrendLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> dailyForecast;

  DailyTrendLinePainter({required this.dailyForecast});

  @override
  void paint(Canvas canvas, Size size) {
    final paintMin = Paint()
      ..color = brandGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintMax = Paint()
      ..color = brandGreen.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Normalize temperatures to fit within canvas height
    final minTemps = dailyForecast.map((day) => day['minTemp'] as double).toList();
    final maxTemps = dailyForecast.map((day) => day['maxTemp'] as double).toList();
    final allTemps = [...minTemps, ...maxTemps];
    final minTemp = allTemps.reduce((a, b) => a < b ? a : b);
    final maxTemp = allTemps.reduce((a, b) => a > b ? a : b);
    final tempRange = maxTemp - minTemp;

    // Calculate points for min and max temperature lines
    final pointsPerDay = size.width / (dailyForecast.length - 1);
    List<Offset> minPoints = [];
    List<Offset> maxPoints = [];

    for (int i = 0; i < dailyForecast.length; i++) {
      final x = i * pointsPerDay;
      final minY = size.height - ((dailyForecast[i]['minTemp'] - minTemp) / tempRange) * (size.height - 20);
      final maxY = size.height - ((dailyForecast[i]['maxTemp'] - minTemp) / tempRange) * (size.height - 20);
      minPoints.add(Offset(x, minY));
      maxPoints.add(Offset(x, maxY));
    }

    // Draw paths
    final minPath = Path()..addPolygon(minPoints, false);
    final maxPath = Path()..addPolygon(maxPoints, false);
    canvas.drawPath(minPath, paintMin);
    canvas.drawPath(maxPath, paintMax);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
