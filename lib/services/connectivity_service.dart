import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Checks both transport availability and actual internet reachability.
///
/// Transport state alone is not enough on emulators: Wi-Fi can remain
/// connected while DNS or internet access is unavailable.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, http.Client? client})
    : _connectivity = connectivity ?? Connectivity(),
      _client = client ?? http.Client();

  final Connectivity _connectivity;
  final http.Client _client;

  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!_hasTransport(results)) return false;

      // Browser CORS policies can reject a probe even while the browser has
      // a working connection. Network-backed requests still have their own
      // error handling, so use the transport signal on web.
      if (kIsWeb) return true;

      // A transport can be present without internet access. This no-content
      // endpoint distinguishes that state from a usable connection.
      final response = await _client
          .get(Uri.parse('https://www.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  bool _hasTransport(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void dispose() => _client.close();
}
