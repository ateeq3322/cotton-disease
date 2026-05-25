// lib/providers/weather_provider.dart
// ─────────────────────────────────────────────────────────────
// CropGuard — Weather state provider
// getSnapshot() — returns a one-off WeatherSnapshot for the
// current location without touching cached state.
// Used by DetectionProvider during inference to capture field
// conditions (temperature + city) at detection time.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart' as w;
import 'detection_provider.dart'; // re-uses WeatherSnapshot model

enum WeatherStatus { idle, loading, loaded, error }

// ── WeatherSnapshot ───────────────────────────────────────────
// Lightweight model used to capture field conditions at the
// exact moment a detection is made. Stored inside Firestore
// alongside the disease record.
class WeatherSnapshot {
  final double temperatureCelsius;
  final String weatherMain;   // e.g. "Clear", "Clouds", "Rain"
  final String cityName;
  final double humidity;      // percentage
  final double windSpeed;     // m/s

  const WeatherSnapshot({
    required this.temperatureCelsius,
    required this.weatherMain,
    required this.cityName,
    required this.humidity,
    required this.windSpeed,
  });

  Map<String, dynamic> toMap() => {
    'temperatureCelsius': temperatureCelsius,
    'weatherMain': weatherMain,
    'cityName': cityName,
    'humidity': humidity,
    'windSpeed': windSpeed,
  };

  factory WeatherSnapshot.fromMap(Map<String, dynamic> map) =>
      WeatherSnapshot(
        temperatureCelsius:
        (map['temperatureCelsius'] as num?)?.toDouble() ?? 0.0,
        weatherMain: map['weatherMain'] as String? ?? 'Unknown',
        cityName: map['cityName'] as String? ?? 'Unknown',
        humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
        windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0.0,
      );

  String get tempFormatted =>
      '${temperatureCelsius.toStringAsFixed(1)}°C';
}

class WeatherProvider extends ChangeNotifier {
  static const _owmKey = 'cc038a8adc8b3726463a271f94e326c6';
  final w.WeatherFactory _wf = w.WeatherFactory(_owmKey);

  WeatherStatus _status = WeatherStatus.idle;
  String? _errorMessage;
  w.Weather? _current;
  List<w.Weather>? _hourlyForecast;
  List<Map<String, dynamic>>? _dailyForecast;

  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 10);

  // ── Public Getters ────────────────────────────────────────
  WeatherStatus get status => _status;
  String? get errorMessage => _errorMessage;
  w.Weather? get current => _current;
  List<w.Weather>? get hourlyForecast => _hourlyForecast;
  List<Map<String, dynamic>>? get dailyForecast => _dailyForecast;

  bool get isLoading => _status == WeatherStatus.loading;
  bool get hasError => _status == WeatherStatus.error;
  bool get hasData => _status == WeatherStatus.loaded;

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  // ── Main Fetch ────────────────────────────────────────────
  Future<void> fetchAll({bool forceRefresh = false}) async {
    if (_isCacheValid && !forceRefresh && hasData) return;

    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final results = await Future.wait([
        _wf.currentWeatherByLocation(position.latitude, position.longitude),
        _wf.fiveDayForecastByLocation(position.latitude, position.longitude),
      ]);

      final w.Weather currentWeather = results[0] as w.Weather;
      final List<w.Weather> forecast = results[1] as List<w.Weather>;

      final hourly = forecast.take(5).toList();

      final DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final Map<DateTime, List<w.Weather>> grouped = {};

      for (final item in forecast) {
        final DateTime day =
        DateTime(item.date!.year, item.date!.month, item.date!.day);
        final int diff = day.difference(today).inDays;
        if (diff >= 0 && diff <= 5) {
          grouped.putIfAbsent(day, () => []).add(item);
        }
      }

      final List<Map<String, dynamic>> daily = grouped.entries.map((e) {
        final temps = e.value.map((x) => x.temperature!.celsius!).toList();
        return {
          'date': e.key,
          'minTemp': temps.reduce((a, b) => a < b ? a : b),
          'maxTemp': temps.reduce((a, b) => a > b ? a : b),
          'weatherMain': e.value.first.weatherMain ?? 'Clear',
        };
      }).toList()
        ..sort((a, b) =>
            (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      _current = currentWeather;
      _hourlyForecast = hourly;
      _dailyForecast = daily;
      _status = WeatherStatus.loaded;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      _status = WeatherStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  // ── getSnapshot() ─────────────────────────────────────────
  // Returns a WeatherSnapshot for the current device location.
  // Does NOT modify cached state or trigger notifyListeners.
  // Safe to call concurrently with fetchAll().
  //
  // Strategy:
  //  1. If cached data is fresh (< 10 min), build snapshot from it —
  //     no extra network call needed.
  //  2. Otherwise fetch a fresh current-weather reading directly.
  //
  // Returns null on any failure — weather is supplementary data,
  // detection must never be blocked by weather errors.
  Future<WeatherSnapshot?> getSnapshot() async {
    try {
      // ── Fast path: reuse cached data ──────────────────────
      if (_isCacheValid && _current != null) {
        return _buildSnapshot(_current!);
      }

      // ── Slow path: one-off fetch ──────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null; // no permission → skip silently
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 8)); // never block inference > 8 s

      final w.Weather weather = await _wf
          .currentWeatherByLocation(pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 8));

      return _buildSnapshot(weather);
    } catch (_) {
      // Silently swallow all errors — weather is optional
      return null;
    }
  }

  // ── Helper: build snapshot from w.Weather ────────────────
  WeatherSnapshot _buildSnapshot(w.Weather weather) => WeatherSnapshot(
    temperatureCelsius: weather.temperature?.celsius ?? 0.0,
    weatherMain: weather.weatherMain ?? 'Unknown',
    cityName: weather.areaName ?? weather.country ?? 'Unknown',
    humidity: weather.humidity?.toDouble() ?? 0.0,
    windSpeed: weather.windSpeed ?? 0.0,
  );
}