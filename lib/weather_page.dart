import 'package:flutter/material.dart';
import 'notification_service.dart';

import 'location_service.dart';
import 'weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService = WeatherService();

  final TextEditingController _latitudeController =
      TextEditingController();
  final TextEditingController _longitudeController =
      TextEditingController();
  final TextEditingController _nameController =
      TextEditingController();

  AgroLocation? _location;
  Map<String, dynamic>? _forecast;
  bool _loading = false;
  String? _error;
  final Set<String> _sentAlertKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _useGps();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather(AgroLocation location) async {
    setState(() {
      _loading = true;
      _error = null;
      _location = location;
    });

    try {
      final data = await _weatherService.getForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) return;

      setState(() {
        _forecast = data;
        _loading = false;
      });
      await _checkWeatherAlerts(data);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _useGps() async {
    try {
      final location = await LocationService.getCurrentLocation();
      await _loadWeather(location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _useManualLocation() async {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      setState(() {
        _error = 'Enter valid latitude and longitude numbers.';
      });
      return;
    }

    try {
      final location = await LocationService.getLocationFromCoordinates(
        latitude: latitude,
        longitude: longitude,
        name: _nameController.text,
      );

      await _loadWeather(location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
  
  
Future<void> _checkWeatherAlerts(
  Map<String, dynamic> forecast,
) async {
  try {
    final hourly = forecast['hourly'] as Map<String, dynamic>?;

    if (hourly == null) return;

    final times = hourly['time'] as List?;
    final probabilities =
        hourly['precipitation_probability'] as List?;
    final temperatures = hourly['temperature_2m'] as List?;

    if (times == null || probabilities == null || temperatures == null) {
      return;
    }

    // Rain alert: probability of 70% or higher
    // during the next 6 forecast hours.
    final rainHours = times.length < 6 ? times.length : 6;

    for (var i = 0;
        i < rainHours && i < probabilities.length;
        i++) {
      final probability = _number(probabilities[i]);

      if (probability >= 70) {
        final key = 'rain_${times[i]}';

        if (_sentAlertKeys.add(key)) {
          await NotificationService.showWeatherAlert(
            id: 201,
            title: 'Rain Alert - Agro Care AI',
            message:
                'Rain probability is $probability% around '
                '${_time(times[i].toString())}. '
                'Check drainage and plan field activities.',
          );
        }

        break;
      }
    }

    // Heat alert: temperature of 35°C or higher
    // during the next 24 forecast hours.
    final heatHours = times.length < 24 ? times.length : 24;

    for (var i = 0;
        i < heatHours && i < temperatures.length;
        i++) {
      final temperature = _decimal(temperatures[i]);

      if (temperature >= 35) {
        final key = 'heat_${times[i]}';

        if (_sentAlertKeys.add(key)) {
          await NotificationService.showWeatherAlert(
            id: 202,
            title: 'Heat Alert - Agro Care AI',
            message:
                'Temperature may reach '
                '${temperature.toStringAsFixed(1)}°C around '
                '${_time(times[i].toString())}. '
                'Check crop moisture and irrigation needs.',
          );
        }

        break;
      }
    }
  } catch (e) {
    debugPrint('Weather alert check failed: $e');
  }
}



  int _number(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _time(String value) {
    if (value.length >= 16) return value.substring(11, 16);
    return value;
  }

  String _day(String value) {
    if (value.length >= 10) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        const days = [
          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
        ];
        return days[date.weekday - 1];
      }
    }
    return value;
  }

  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.water_drop;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud_queue;
  }

  String _farmingAdvice(Map<String, dynamic> current) {
    final rain = _decimal(current['rain']);
    final precipitation = _decimal(current['precipitation']);
    final temperature = _decimal(current['temperature_2m']);
    final wind = _decimal(current['wind_speed_10m']);
    final code = _number(current['weather_code']);

    if (code >= 95) {
      return 'Thunderstorms are reported. Avoid fieldwork during lightning '
          'and secure exposed equipment.';
    }
    if (rain > 0 || precipitation > 0) {
      return 'Rain is occurring or expected now. Check field drainage and '
          'avoid unnecessary irrigation while the soil is wet.';
    }
    if (temperature >= 35) {
      return 'High temperatures may stress crops. Check soil moisture and '
          'irrigate according to crop needs and local guidance.';
    }
    if (wind >= 30) {
      return 'Strong winds may affect spraying and young plants. Consider '
          'postponing spraying and secure vulnerable supports.';
    }
    if (code == 0 || code == 1) {
      return 'Conditions appear mostly clear. Check soil moisture before '
          'irrigating and follow the crop’s usual watering schedule.';
    }
    return 'Check soil moisture and local field conditions before irrigation '
        'or spraying. Forecasts cannot replace on-site assessment.';
  }

  @override
  Widget build(BuildContext context) {
    final current = _forecast?['current'] as Map<String, dynamic>?;
    final hourly = _forecast?['hourly'] as Map<String, dynamic>?;
    final daily = _forecast?['daily'] as Map<String, dynamic>?;

    return Scaffold(
      
appBar: AppBar(
  title: const Text('Farm Weather'),
  backgroundColor: Colors.green.shade100,
  actions: [
    IconButton(
      tooltip: 'Test Notification',
      icon: const Icon(
        Icons.notifications_active_outlined,
        color: Colors.green,
      ),
      onPressed: () async {
        try {
          await NotificationService.showWeatherAlert(
            title: 'Agro Care AI - Weather Alert',
            message:
                'Test successful! Your weather notification system is working.',
          );

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test notification sent!'),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification failed: $e'),
            ),
          );
        }
      },
    ),
  ],
),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_location != null) {
              await _loadWeather(_location!);
            } else {
              await _useGps();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose your location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _useGps,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Use current GPS location'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Village or field name (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'e.g. 12.9716',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'e.g. 77.5946',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _loading ? null : _useManualLocation,
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Get weather for these coordinates'),
                        ),
                      ),
                      if (_location != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_location!.name} '
                          '(${_location!.latitude.toStringAsFixed(4)}, '
                          '${_location!.longitude.toStringAsFixed(4)})',
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ),
              if (current != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          WeatherService.weatherDescription(
                            _number(current['weather_code']),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _weatherIcon(_number(current['weather_code'])),
                          size: 48,
                          color: Colors.green.shade700,
                        ),
                        Text(
                          '${_decimal(current['temperature_2m']).round()}°C',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Feels like '
                          '${_decimal(current['apparent_temperature']).round()}°C',
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _metric(
                              Icons.water_drop,
                              'Humidity',
                              '${_number(current['relative_humidity_2m'])}%',
                            ),
                            _metric(
                              Icons.air,
                              'Wind',
                              '${_number(current['wind_speed_10m'])} km/h',
                            ),
                            _metric(
                              Icons.grain,
                              'Rain',
                              '${_decimal(current['rain']).toStringAsFixed(1)} mm',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hourly != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Hourly rain forecast',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (hourly['time'] as List).length < 24
                        ? (hourly['time'] as List).length
                        : 24,
                    itemBuilder: (context, index) {
                      final times = hourly['time'] as List;
                      final rain = hourly['precipitation'] as List;
                      final probability =
                          hourly['precipitation_probability'] as List;

                      return SizedBox(
                        width: 90,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_time(times[index].toString())),
                                const Icon(Icons.water_drop, color: Colors.blue),
                                Text('${_number(probability[index])}%'),
                                Text(
                                  '${_decimal(rain[index]).toStringAsFixed(1)} mm',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (daily != null) ...[
                const SizedBox(height: 20),
                const Text(
                  '7-day forecast',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  (daily['time'] as List).length,
                  (index) {
                    final dates = daily['time'] as List;
                    final codes = daily['weather_code'] as List;
                    final max = daily['temperature_2m_max'] as List;
                    final min = daily['temperature_2m_min'] as List;
                    final rain = daily['precipitation_sum'] as List;
                    final probability =
                        daily['precipitation_probability_max'] as List;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _weatherIcon(_number(codes[index])),
                          color: Colors.green.shade700,
                        ),
                        title: Text(_day(dates[index].toString())),
                        subtitle: Text(
                          '${WeatherService.weatherDescription(_number(codes[index]))}'
                          ' • Rain chance ${_number(probability[index])}%',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_number(max[index])}° / ${_number(min[index])}°',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${_decimal(rain[index]).toStringAsFixed(1)} mm'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (current != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Farming weather advice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.agriculture, size: 30),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_farmingAdvice(current))),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Weather guidance is general. Check local conditions and '
                    'official agricultural advice before making farm decisions.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
