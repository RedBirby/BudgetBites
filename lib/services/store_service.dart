import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config/app_config.dart';
import '../domain/models/grocery_store.dart';

class StoreSearchResult {
  const StoreSearchResult({
    required this.center,
    required this.stores,
    this.zipCode,
  });
  final LatLng center;
  final List<GroceryStore> stores;
  final String? zipCode;
}

class StoreService {
  StoreService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _distance = Distance();
  static final _overpassEndpoints = <Uri>[
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.private.coffee/api/interpreter'),
  ];

  Future<LatLng> resolveZip(String zip) async {
    try {
      final response = await _client
          .get(
            Uri.parse('https://api.zippopotam.us/us/$zip'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const FormatException('ZIP code was not found.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List?;
      if (places == null || places.isEmpty) {
        throw const FormatException('ZIP code was not found.');
      }
      final place = places.first as Map<String, dynamic>;
      return LatLng(
        double.parse(place['latitude'] as String),
        double.parse(place['longitude'] as String),
      );
    } on TimeoutException {
      throw Exception(
        'ZIP lookup timed out. Check your connection and try again.',
      );
    } on FormatException {
      throw Exception('ZIP code was not found.');
    } on http.ClientException {
      throw Exception(
        'ZIP lookup is unavailable. Check your connection and try again.',
      );
    }
  }

  Future<StoreSearchResult> searchByZip(String zip) async {
    final center = await resolveZip(zip);
    final stores = await searchNearby(center);
    return StoreSearchResult(center: center, stores: stores, zipCode: zip);
  }

  Future<List<GroceryStore>> searchNearby(LatLng center) async {
    if (AppConfig.placesProxyUrl.isNotEmpty) return _searchProxy(center);
    return _searchOverpass(center);
  }

  Future<List<GroceryStore>> _searchProxy(LatLng center) async {
    final uri = Uri.parse(AppConfig.placesProxyUrl).replace(
      queryParameters: {
        'lat': '${center.latitude}',
        'lng': '${center.longitude}',
        'radius': '8000',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Store service unavailable.');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final location = LatLng(
        (item['lat'] as num).toDouble(),
        (item['lng'] as num).toDouble(),
      );
      return GroceryStore(
        id: item['id'].toString(),
        name: item['name'] as String,
        address: item['address'] as String? ?? 'Address available on map',
        location: location,
        distanceMiles: _distance.as(LengthUnit.Mile, center, location),
        website: Uri.tryParse(item['website'] as String? ?? ''),
      );
    }).toList();
  }

  Future<List<GroceryStore>> _searchOverpass(LatLng center) async {
    final query =
        '''[out:json][timeout:12];(
node["shop"~"supermarket|grocery"](around:8000,${center.latitude},${center.longitude});
way["shop"~"supermarket|grocery"](around:8000,${center.latitude},${center.longitude});
relation["shop"~"supermarket|grocery"](around:8000,${center.latitude},${center.longitude});
);out center tags;''';
    var receivedValidResponse = false;
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _client
            .post(
              endpoint,
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          debugPrint(
            'Overpass POST returned HTTP ${response.statusCode}: $endpoint',
          );
          continue;
        }
        receivedValidResponse = true;
        final stores = _parseOverpass(response.body, center);
        if (stores.isNotEmpty) return stores;
      } on TimeoutException {
        debugPrint('Overpass POST timed out: $endpoint');
        continue;
      } on http.ClientException {
        debugPrint('Overpass POST failed: $endpoint');
        continue;
      } on FormatException {
        debugPrint('Overpass POST returned invalid JSON: $endpoint');
        continue;
      }
    }

    // Some browsers or networks block cross-origin form POST requests even
    // though the same Overpass endpoint is reachable with a query-string GET.
    // Retry with GET so ZIP and device searches work in the web build too.
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _client
            .get(
              endpoint.replace(queryParameters: {'data': query}),
              headers: const {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          debugPrint(
            'Overpass GET returned HTTP ${response.statusCode}: $endpoint',
          );
          continue;
        }
        receivedValidResponse = true;
        final stores = _parseOverpass(response.body, center);
        if (stores.isNotEmpty) return stores;
      } on TimeoutException {
        debugPrint('Overpass GET timed out: $endpoint');
        continue;
      } on http.ClientException {
        debugPrint('Overpass GET failed: $endpoint');
        continue;
      } on FormatException {
        debugPrint('Overpass GET returned invalid JSON: $endpoint');
        continue;
      }
    }

    // Photon is a lightweight OpenStreetMap geocoder with a browser/mobile-
    // friendly JSON endpoint. It is a useful fallback when Overpass is rate
    // limited or blocked by the current network (a common emulator setup).
    final photonStores = await _searchPhoton(center);
    if (photonStores.isNotEmpty) return photonStores;

    final nominatimStores = await _searchNominatim(center);
    if (nominatimStores.isNotEmpty) return nominatimStores;

    if (receivedValidResponse) {
      throw Exception(
        'No grocery stores were found near this location. Try a nearby ZIP code.',
      );
    }
    throw Exception(
      'Live store lookup is temporarily unavailable. Try again or search with a ZIP code.',
    );
  }

  Future<List<GroceryStore>> _searchPhoton(LatLng center) async {
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': 'supermarket',
        'lat': '${center.latitude}',
        'lon': '${center.longitude}',
        'limit': '30',
        'lang': 'en',
      });
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('Photon store lookup returned HTTP ${response.statusCode}');
        return const [];
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final features = payload['features'] as List? ?? const [];
      final stores = <GroceryStore>[];
      final seen = <String>{};
      for (final raw in features) {
        final feature = Map<String, dynamic>.from(raw as Map);
        final properties = Map<String, dynamic>.from(
          feature['properties'] as Map? ?? const {},
        );
        final geometry = Map<String, dynamic>.from(
          feature['geometry'] as Map? ?? const {},
        );
        final coordinates = geometry['coordinates'] as List?;
        if (coordinates == null || coordinates.length < 2) continue;
        final lon = (coordinates[0] as num?)?.toDouble();
        final lat = (coordinates[1] as num?)?.toDouble();
        final name = properties['name'] as String?;
        if (lat == null || lon == null || name == null || name.trim().isEmpty) {
          continue;
        }
        final key =
            '${name.toLowerCase()}-${lat.toStringAsFixed(4)}-${lon.toStringAsFixed(4)}';
        if (!seen.add(key)) continue;
        final address = [
          properties['housenumber'],
          properties['street'],
          properties['city'] ?? properties['locality'],
          properties['state'],
          properties['postcode'],
        ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
        final location = LatLng(lat, lon);
        stores.add(
          GroceryStore(
            id: 'photon-${properties['osm_type'] ?? 'place'}-${properties['osm_id'] ?? key}',
            name: name,
            address: address.isEmpty ? 'Address available on map' : address,
            location: location,
            distanceMiles: _distance.as(LengthUnit.Mile, center, location),
            website: Uri.tryParse(properties['website'] as String? ?? ''),
          ),
        );
      }
      stores.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      return stores.take(12).toList();
    } on TimeoutException {
      debugPrint('Photon store lookup timed out');
      return const [];
    } on http.ClientException {
      debugPrint('Photon store lookup failed');
      return const [];
    } on FormatException {
      debugPrint('Photon store lookup returned invalid JSON');
      return const [];
    }
  }

  Future<List<GroceryStore>> _searchNominatim(LatLng center) async {
    try {
      const delta = 0.08;
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': 'supermarket',
        'limit': '30',
        'bounded': '1',
        'viewbox':
            '${center.longitude - delta},${center.latitude + delta},${center.longitude + delta},${center.latitude - delta}',
      });
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'BudgetBite/1.0 (grocery planning prototype)',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint(
          'Nominatim store lookup returned HTTP ${response.statusCode}',
        );
        return const [];
      }
      final results = jsonDecode(response.body) as List? ?? const [];
      final stores = <GroceryStore>[];
      final seen = <String>{};
      for (final raw in results) {
        final item = Map<String, dynamic>.from(raw as Map);
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        final displayName = item['display_name'] as String?;
        if (lat == null || lon == null || displayName == null) continue;
        final name = (item['name'] as String?)?.trim();
        final label = name == null || name.isEmpty
            ? displayName.split(',').first.trim()
            : name;
        final key =
            '${label.toLowerCase()}-${lat.toStringAsFixed(4)}-${lon.toStringAsFixed(4)}';
        if (!seen.add(key)) continue;
        final location = LatLng(lat, lon);
        final extraTags = Map<String, dynamic>.from(
          item['extratags'] as Map? ?? const {},
        );
        stores.add(
          GroceryStore(
            id: 'nominatim-${item['place_id'] ?? key}',
            name: label,
            address: displayName,
            location: location,
            distanceMiles: _distance.as(LengthUnit.Mile, center, location),
            website: Uri.tryParse(extraTags['website'] as String? ?? ''),
          ),
        );
      }
      stores.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      return stores.take(12).toList();
    } on TimeoutException {
      debugPrint('Nominatim store lookup timed out');
      return const [];
    } on http.ClientException {
      debugPrint('Nominatim store lookup failed');
      return const [];
    } on FormatException {
      debugPrint('Nominatim store lookup returned invalid JSON');
      return const [];
    }
  }

  List<GroceryStore> _parseOverpass(String body, LatLng center) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final seen = <String>{};
    final stores = <GroceryStore>[];
    for (final raw in data['elements'] as List? ?? const []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final tags = Map<String, dynamic>.from(item['tags'] as Map? ?? const {});
      final centerData = Map<String, dynamic>.from(
        item['center'] as Map? ?? const {},
      );
      final lat =
          (item['lat'] as num?)?.toDouble() ??
          (centerData['lat'] as num?)?.toDouble();
      final lng =
          (item['lon'] as num?)?.toDouble() ??
          (centerData['lon'] as num?)?.toDouble();
      final name = tags['name'] as String? ?? tags['brand'] as String?;
      if (lat == null ||
          lng == null ||
          name == null ||
          !seen.add(name.toLowerCase())) {
        continue;
      }
      final location = LatLng(lat, lng);
      final street = [
        tags['addr:housenumber'],
        tags['addr:street'],
      ].whereType<String>().join(' ');
      final address = [
        street,
        tags['addr:city'],
        tags['addr:state'],
        tags['addr:postcode'],
      ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
      stores.add(
        GroceryStore(
          id: 'osm-${item['type']}-${item['id']}',
          name: name,
          address: address.isEmpty ? 'Address available on map' : address,
          location: location,
          distanceMiles: _distance.as(LengthUnit.Mile, center, location),
          website: Uri.tryParse(tags['website'] as String? ?? ''),
        ),
      );
    }
    stores.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
    return stores.take(12).toList();
  }
}
