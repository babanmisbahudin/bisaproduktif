import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dynamic_scene_painter.dart';

// ── Data classes ─────────────────────────────────────────────────────────

/// Struktur data cuaca dari OpenWeatherMap API
class WeatherData {
  final WeatherType type;
  final double tempC;
  final String city;
  final String description;
  final int humidity;
  final double windSpeed;

  const WeatherData({
    required this.type,
    required this.tempC,
    required this.city,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });
}

/// Mendeteksi cuaca real-time dari OpenWeatherMap (primary) atau wttr.in (fallback).
/// Lokasi: GPS (jika diizinkan) → IP fallback.
class WeatherService {
  WeatherService._();

  static WeatherData? _cachedData;
  static DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 30);

  static WeatherData? get current => _cachedData;

  /// Ambil cuaca dari OpenWeatherMap (jika API key ada) atau fallback ke wttr.in.
  /// Return null jika offline dan belum ada cache.
  static Future<WeatherData?> fetch() async {
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedData;
    }

    // Coba OpenWeatherMap dulu (jika API key ada)
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('owm_api_key');

    if (apiKey != null && apiKey.isNotEmpty) {
      final data = await _fetchOpenWeatherMap(apiKey);
      if (data != null) {
        _cachedData = data;
        _lastFetch = DateTime.now();
        return data;
      }
    }

    // Fallback ke wttr.in
    final type = await _fetchWttrIn();
    final data = WeatherData(
      type: type,
      tempC: 0,
      city: 'Lokasi Anda',
      description: _getDescription(type),
      humidity: 0,
      windSpeed: 0,
    );
    _cachedData = data;
    _lastFetch = DateTime.now();
    return data;
  }

  /// Dapatkan koordinat GPS (minta izin jika belum).
  /// Return null jika GPS tidak tersedia atau ditolak.
  static Future<Map<String, double>?> _getGPSLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // hemat baterai
          timeLimit: Duration(seconds: 10),
        ),
      );
      return {'lat': pos.latitude, 'lon': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  /// Dapatkan koordinat dari IP sebagai fallback
  static Future<Map<String, double>?> _getIPLocation(HttpClient client) async {
    try {
      final locReq = await client
          .getUrl(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 8));
      locReq.headers.set('User-Agent', 'BisaProduktif/1.0');

      final locRes = await locReq.close().timeout(const Duration(seconds: 8));
      final locBody =
          (await locRes.transform(const SystemEncoding().decoder).toList())
              .join();

      final locJson = jsonDecode(locBody) as Map<String, dynamic>;
      final lat = locJson['latitude'] as double?;
      final lon = locJson['longitude'] as double?;
      if (lat == null || lon == null) return null;
      return {'lat': lat, 'lon': lon};
    } catch (_) {
      return null;
    }
  }

  /// Fetch dari OpenWeatherMap API (GPS → IP fallback untuk lokasi)
  static Future<WeatherData?> _fetchOpenWeatherMap(String apiKey) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..badCertificateCallback = (_, _, _) => true;

      // 1. Coba GPS dulu, fallback ke IP
      final gpsLoc = await _getGPSLocation();
      Map<String, double>? loc = gpsLoc ?? await _getIPLocation(client);
      if (loc == null) return null;

      final lat = loc['lat']!;
      final lon = loc['lon']!;

      // 2. Fetch cuaca dari OpenWeatherMap
      final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id',
      );
      final weatherReq = await client
          .getUrl(weatherUrl)
          .timeout(const Duration(seconds: 8));
      weatherReq.headers.set('User-Agent', 'BisaProduktif/1.0');

      final weatherRes =
          await weatherReq.close().timeout(const Duration(seconds: 8));
      final weatherBody =
          (await weatherRes.transform(const SystemEncoding().decoder).toList())
              .join();
      client.close();

      if (weatherRes.statusCode != 200) return null;

      final json = jsonDecode(weatherBody) as Map<String, dynamic>;
      final mainData = json['main'] as Map<String, dynamic>?;
      final weatherList = json['weather'] as List?;

      if (mainData == null || weatherList == null || weatherList.isEmpty) {
        return null;
      }

      final tempC = (mainData['temp'] as num?)?.toDouble() ?? 0;
      final humidity = (mainData['humidity'] as num?)?.toInt() ?? 0;
      final windSpeed =
          ((json['wind'] as Map?)?['speed'] as num?)?.toDouble() ?? 0;
      final city = json['name'] as String? ?? 'Unknown';
      final condition = weatherList[0]['main'] as String? ?? '';
      final description = weatherList[0]['description'] as String? ?? '';

      final type = _parseOpenWeatherCondition(condition);

      return WeatherData(
        type: type,
        tempC: tempC,
        city: city,
        description: description,
        humidity: humidity,
        windSpeed: windSpeed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch dari wttr.in (fallback, gratis tanpa API key)
  static Future<WeatherType> _fetchWttrIn() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6)
        ..badCertificateCallback = (_, _, _) => true;

      final req = await client
          .getUrl(Uri.parse('https://wttr.in/?format=%C'))
          .timeout(const Duration(seconds: 8));
      req.headers.set('User-Agent', 'BisaProduktif/1.0');

      final res = await req.close().timeout(const Duration(seconds: 8));
      final body =
          (await res.transform(const SystemEncoding().decoder).toList())
              .join();
      client.close();

      return _parseWttrInCondition(body.trim().toLowerCase());
    } catch (_) {
      return WeatherType.clear;
    }
  }

  /// Parse kondisi dari OpenWeatherMap (main field)
  static WeatherType _parseOpenWeatherCondition(String condition) {
    if (_contains(condition.toLowerCase(), [
      'rain', 'drizzle', 'thunderstorm',
    ])) {
      return WeatherType.rainy;
    }

    if (_contains(condition.toLowerCase(), [
      'clear', 'sunny',
    ])) {
      return WeatherType.hot;
    }

    if (_contains(condition.toLowerCase(), [
      'cloud', 'overcast', 'haze', 'mist', 'smoke',
    ])) {
      return WeatherType.cloudy;
    }

    return WeatherType.clear;
  }

  /// Parse kondisi dari wttr.in (text description)
  static WeatherType _parseWttrInCondition(String condition) {
    if (_contains(condition, [
      'rain', 'drizzle', 'shower', 'thunder', 'storm', 'hujan',
      'blizzard', 'sleet', 'fog', 'mist',
    ])) {
      return WeatherType.rainy;
    }

    if (_contains(condition, [
      'sunny', 'clear', 'hot', 'blazing', 'cerah', 'panas',
    ])) {
      return WeatherType.hot;
    }

    if (_contains(condition, [
      'cloud', 'overcast', 'haze', 'smoke', 'mendung',
    ])) {
      return WeatherType.cloudy;
    }

    return WeatherType.clear;
  }

  static String _getDescription(WeatherType type) {
    return switch (type) {
      WeatherType.rainy => 'Hujan',
      WeatherType.hot => 'Cerah',
      WeatherType.cloudy => 'Berawan',
      WeatherType.clear => 'Cerah',
    };
  }

  static bool _contains(String text, List<String> kw) =>
      kw.any((k) => text.contains(k));

  /// Setup API key untuk OpenWeatherMap (dipanggil dari home_screen.dart)
  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owm_api_key', key);
    _lastFetch = null; // Force refresh
  }

  // ── Reverse Geocoding ─────────────────────────────────────────────────────

  /// Ambil alamat lengkap dari GPS (kota, provinsi, negara) via Nominatim OSM.
  /// Return null jika GPS tidak diizinkan atau offline.
  static Future<Map<String, String>?> getFullAddress() async {
    final gpsLoc = await _getGPSLocation();
    if (gpsLoc == null) return null;
    return _reverseGeocode(gpsLoc['lat']!, gpsLoc['lon']!);
  }

  static Future<Map<String, String>?> _reverseGeocode(
      double lat, double lon) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..badCertificateCallback = (_, _, _) => true;

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lon&addressdetails=1',
      );
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      // Nominatim wajib User-Agent yang informatif
      req.headers.set('User-Agent', 'BisaProduktif/1.0 (android)');
      req.headers.set('Accept-Language', 'id'); // nama wilayah Bahasa Indonesia

      final res = await req.close().timeout(const Duration(seconds: 8));
      final body =
          (await res.transform(const SystemEncoding().decoder).toList()).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      // Kota/kabupaten: coba beberapa field sesuai tingkat administratif
      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'] ??
              '') as String;
      final state = (address['state'] ?? address['province'] ?? '') as String;
      final country = (address['country'] ?? '') as String;
      final countryCode =
          (address['country_code'] as String? ?? '').toUpperCase();

      // Format ringkas: "Bandung, Jawa Barat"
      final parts = [city, state].where((s) => s.isNotEmpty).toList();
      final displayAddress = parts.isNotEmpty ? parts.join(', ') : country;

      return {
        'city': city,
        'state': state,
        'country': country,
        'countryCode': countryCode,
        'lat': lat.toStringAsFixed(5),
        'lon': lon.toStringAsFixed(5),
        'displayAddress': displayAddress,
      };
    } catch (_) {
      return null;
    }
  }
}
