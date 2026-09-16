import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../domain/models/grocery_store.dart';

class TaxEstimate {
  const TaxEstimate({required this.rate, required this.label});
  final double rate;
  final String label;
}

class TaxService {
  TaxService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _californiaCityRates = <String, double>{
    'san gabriel': 10.5,
    'arcadia': 10.5,
    'pasadena': 10.5,
    'rosemead': 9.75,
    'temple city': 9.75,
  };

  Future<TaxEstimate> estimateForStore(GroceryStore store) async {
    if (AppConfig.taxProxyUrl.isNotEmpty && store.zipCode != null) {
      final uri = Uri.parse(AppConfig.taxProxyUrl).replace(
        queryParameters: {'zip': store.zipCode!, 'address': store.address},
      );
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TaxEstimate(
          rate: (data['rate'] as num).toDouble(),
          label: data['label'] as String? ?? 'Store-area estimate',
        );
      }
    }
    final address = store.address.toLowerCase();
    for (final entry in _californiaCityRates.entries) {
      if (address.contains(entry.key)) {
        return TaxEstimate(
          rate: entry.value,
          label: '${store.name} area estimate',
        );
      }
    }
    return const TaxEstimate(
      rate: 0,
      label: 'Enter the retailer rate; grocery exemptions vary by item.',
    );
  }
}
