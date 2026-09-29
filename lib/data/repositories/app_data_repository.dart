import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/grocery_store.dart';
import '../../domain/models/recipe.dart';
import '../../services/location_service.dart';
import '../../services/recipe_service.dart';
import '../../services/store_service.dart';
import '../../services/tax_service.dart';

/// A user-facing data error that can safely be rendered by a screen.
class DataLayerException implements Exception {
  const DataLayerException(this.message);

  final String message;

  @override
  String toString() => message;
}

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(),
);

/// Coordinates remote/device data sources for the application state layer.
/// Screens never call HTTP, GPS, or tax services directly.
class AppDataRepository {
  AppDataRepository({
    RecipeService? recipeService,
    LocationService? locationService,
    StoreService? storeService,
    TaxService? taxService,
  }) : _recipeService = recipeService ?? RecipeService(),
       _locationService = locationService ?? LocationService(),
       _storeService = storeService ?? StoreService(),
       _taxService = taxService ?? TaxService();

  final RecipeService _recipeService;
  final LocationService _locationService;
  final StoreService _storeService;
  final TaxService _taxService;

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      return await _recipeService.search(query);
    } catch (error) {
      throw DataLayerException(
        _message(error, fallback: 'Recipe search is unavailable right now.'),
      );
    }
  }

  Future<StoreSearchResult> searchStoresByZip(String zip) async {
    try {
      return await _storeService.searchByZip(zip);
    } catch (error) {
      throw DataLayerException(
        _message(
          error,
          fallback: 'Nearby store lookup is unavailable right now.',
        ),
      );
    }
  }

  Future<StoreSearchResult> searchStoresAtCurrentLocation() async {
    try {
      final center = await _locationService.currentLocation();
      final stores = await _storeService.searchNearby(center);
      return StoreSearchResult(center: center, stores: stores);
    } catch (error) {
      throw DataLayerException(
        _message(
          error,
          fallback:
              'Live location is unavailable. Allow location access or enter a ZIP code.',
        ),
      );
    }
  }

  Future<TaxEstimate> estimateTax(GroceryStore store) async {
    try {
      return await _taxService.estimateForStore(store);
    } catch (error) {
      // A tax provider should never block the shopping plan. The UI can show
      // the returned label and let the user enter a manual estimate instead.
      return TaxEstimate(
        rate: 0,
        label: _message(
          error,
          fallback: 'Tax estimate unavailable; enter the store rate manually.',
        ),
      );
    }
  }

  String _message(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return fallback;
    }

    // Keep implementation details such as SocketException and DNS failures
    // out of the UI. These can occur in any remote/device-backed flow, so the
    // repository presents one actionable message that is easy to understand.
    final normalized = message.toLowerCase();
    if (normalized.contains('failed host lookup') ||
        normalized.contains('socketexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('network') ||
        normalized.contains('no internet') ||
        normalized.contains('unreachable') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection reset') ||
        normalized.contains('connection closed')) {
      return 'No internet connection. Please reconnect and try again.';
    }
    return message;
  }
}
