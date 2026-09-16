import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocationService {
  Future<LatLng> currentLocation() async {
    try {
      // On web, the browser owns the location-service switch. The web
      // implementation may report it as disabled before the permission prompt
      // has been shown, so let getCurrentPosition request it directly.
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(
          'Location services are turned off. Turn them on or enter a ZIP code.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationException(
          'Location permission was not granted. Allow location access or enter a ZIP code.',
        );
      }
      Position result;
      try {
        result = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            // A low-power fused request is more reliable on Android Studio's
            // emulator than waiting for a fresh GPS fix.
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (error) {
        // Emulators often expose a valid last-known fused location while the
        // GPS provider is still warming up. Use it instead of failing the
        // entire store search after the timeout.
        debugPrint(
          'Location request failed; trying last-known position: $error',
        );
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        result = lastKnown;
      }
      if (!result.latitude.isFinite || !result.longitude.isFinite) {
        throw const LocationException(
          'Your device returned an invalid location. Enter a ZIP code instead.',
        );
      }
      return LatLng(result.latitude, result.longitude);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(
        'Live location is unavailable. Allow location access for this site, then try again, or enter a ZIP code.',
      );
    }
  }
}
