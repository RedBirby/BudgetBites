import '../domain/models/grocery_store.dart';

class RetailerLinkService {
  /// Returns true when the retailer has a known product-search experience.
  ///
  /// For smaller stores, we can still open their public website, but we do
  /// not imply that the site exposes live inventory.
  bool supportsInventorySearch(GroceryStore store) {
    final name = store.name.toLowerCase();
    return name.contains('trader joe') ||
        name.contains('h mart') ||
        name.contains('hmart') ||
        name.contains('walmart') ||
        name.contains('target') ||
        name.contains('safeway') ||
        name.contains('vons') ||
        RegExp('kroger|ralphs|food 4 less').hasMatch(name);
  }

  String actionLabel(GroceryStore store, String ingredient) {
    if (supportsInventorySearch(store)) {
      return 'Search $ingredient online';
    }
    if (store.website != null) {
      return 'Open store website';
    }
    return 'Website unavailable';
  }

  String? availabilityNote(GroceryStore store) {
    if (store.website == null) {
      return 'No store website or online inventory is listed.';
    }
    if (!supportsInventorySearch(store)) {
      return 'Website available, but live inventory may not be listed.';
    }
    return null;
  }

  Uri? productSearch(GroceryStore store, String ingredient) {
    final name = store.name.toLowerCase();
    final query = Uri.encodeQueryComponent(ingredient);
    if (name.contains("trader joe")) {
      return Uri.parse(
        'https://www.traderjoes.com/home/search?q=$query&section=products&global=no',
      );
    }
    if (name.contains('h mart') || name.contains('hmart')) {
      return Uri.parse('https://www.hmart.com/$query?_q=$query&map=ft');
    }
    if (name.contains('walmart')) {
      return Uri.parse('https://www.walmart.com/search?q=$query');
    }
    if (name.contains('target')) {
      return Uri.parse('https://www.target.com/s?searchTerm=$query');
    }
    if (name.contains('safeway')) {
      return Uri.parse(
        'https://www.safeway.com/shop/search-results.html?q=$query',
      );
    }
    if (name.contains('vons')) {
      return Uri.parse(
        'https://www.vons.com/shop/search-results.html?q=$query',
      );
    }
    if (RegExp('kroger|ralphs|food 4 less').hasMatch(name)) {
      return Uri.parse('https://www.kroger.com/search?query=$query');
    }
    return store.website;
  }
}
