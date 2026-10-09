
import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl =
      'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'is_day,precipitation,rain,showers,weather_code,wind_speed_10m',
        'hourly':
            'temperature_2m,precipitation_probability,precipitation,'
            'rain,weather_code',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_probability_max,precipitation_sum,'
            'sunrise,sunset',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Weather service returned status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> ||
          !decoded.containsKey('current') ||
          !decoded.containsKey('hourly') ||
          !decoded.containsKey('daily')) {
        throw Exception('Weather data format was unexpected.');
      }

      return decoded;
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception(
        'Unable to load weather. Check your internet connection and try again.',
      );
    }
  }

  static String weatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code == 85 || code == 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown conditions';
  }
}
