
import 'package:geolocator/geolocator.dart';

class AgroLocation {
  final double latitude;
  final double longitude;
  final String name;

  const AgroLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}

class LocationService {
  static Future<AgroLocation> getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'GPS is disabled. Enable location or enter coordinates manually.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission unavailable. Enter coordinates manually.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return AgroLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      name: 'Current location',
    );
  }

  static Future<AgroLocation> getLocationFromCoordinates({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    if (latitude < -90 || latitude > 90) {
      throw Exception('Latitude must be between -90 and 90.');
    }

    if (longitude < -180 || longitude > 180) {
      throw Exception('Longitude must be between -180 and 180.');
    }

    return AgroLocation(
      latitude: latitude,
      longitude: longitude,
      name: name.trim().isEmpty ? 'Selected location' : name.trim(),
    );
  }
}
