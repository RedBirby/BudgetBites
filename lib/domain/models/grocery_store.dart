import 'package:latlong2/latlong.dart';

class GroceryStore {
  const GroceryStore({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.distanceMiles,
    this.website,
  });

  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double distanceMiles;
  final Uri? website;

  String? get zipCode => RegExp(r'\b\d{5}\b').firstMatch(address)?.group(0);
}
