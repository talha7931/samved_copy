import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> ensureLocationPermission() async {
    if (kIsWeb) {
      var s = await Geolocator.checkPermission();
      if (s == LocationPermission.denied) {
        s = await Geolocator.requestPermission();
      }
      return s == LocationPermission.always || s == LocationPermission.whileInUse;
    }
    final status = await Permission.location.request();
    if (status.isGranted) return true;
    final s = await Geolocator.checkPermission();
    if (s == LocationPermission.denied) {
      final r = await Geolocator.requestPermission();
      return r == LocationPermission.always || r == LocationPermission.whileInUse;
    }
    return s == LocationPermission.always || s == LocationPermission.whileInUse;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensureLocationPermission();
    if (!ok) return null;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Haversine distance in meters (ticket point vs current GPS).
  double distanceMeters({
    required double ticketLat,
    required double ticketLng,
    required double hereLat,
    required double hereLng,
  }) {
    return Geolocator.distanceBetween(
      ticketLat,
      ticketLng,
      hereLat,
      hereLng,
    );
  }
}
