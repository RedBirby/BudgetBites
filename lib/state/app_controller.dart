import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/repositories/app_data_repository.dart';
import '../data/seed_data.dart';
import '../domain/models/budget_item.dart';
import '../domain/models/dietary_preferences.dart';
import '../domain/models/grocery_store.dart';
import '../domain/models/planned_recipe.dart';
import '../domain/models/recipe.dart';
import '../domain/services/ingredient_scaler.dart';
import '../domain/models/user_session.dart';
import '../services/firebase_account_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/local_storage_service.dart';
import 'app_state.dart';

String _normalizeSearchText(String value) => value
    .toLowerCase()
    .replaceAll('&', ' and ')
    .replaceAll(RegExp('[^a-z0-9]+'), ' ')
    .trim();

int recipeSearchRelevance(Recipe recipe, String rawQuery) {
  final query = _normalizeSearchText(rawQuery);
  if (query.isEmpty) return 0;

  final name = recipe.normalizedName;
  if (name == query) return 1000;
  if (name.startsWith(query)) return 900;

  var score = name.contains(query) ? 800 : 0;
  final ingredients = _normalizeSearchText(
    recipe.ingredients.map((item) => item.name).join(' '),
  );
  if (ingredients.contains(query)) score = max(score, 700);

  final tags = _normalizeSearchText(recipe.tags.join(' '));
  if (tags.contains(query)) score = max(score, 600);

  final queryWords = query.split(' ').where((word) => word.length > 1);
  for (final word in queryWords) {
    if (name.split(' ').contains(word)) score += 80;
    if (ingredients.split(' ').contains(word)) score += 35;
    if (tags.split(' ').contains(word)) score += 20;
  }
  return score;
}

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  final controller = AppController(
    storage: ref.watch(localStorageProvider),
    dataRepository: ref.watch(appDataRepositoryProvider),
    firebaseAuth: ref.watch(firebaseAuthServiceProvider),
    firebaseAccounts: ref.watch(firebaseAccountRepositoryProvider),
  );
  controller.initialize();
  return controller;
});

final visibleRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(appControllerProvider);
  final query = state.activeSearchQuery;
  final unique = <String, Recipe>{};
  for (final recipe in state.recipes) {
    final relevance = recipeSearchRelevance(recipe, query);
    if (recipeFitsPreferences(recipe, state.preferences) &&
        (query.isEmpty || relevance > 0)) {
      unique.putIfAbsent(recipe.normalizedName, () => recipe);
    }
  }
  final result = unique.values.toList();
  result.sort((a, b) {
    if (query.isNotEmpty) {
      final searchOrder = recipeSearchRelevance(
        b,
        query,
      ).compareTo(recipeSearchRelevance(a, query));
      if (searchOrder != 0) return searchOrder;
    }
    final score = recipeMatchScore(
      b,
      state.preferences,
    ).compareTo(recipeMatchScore(a, state.preferences));
    return score != 0
        ? score
        : a.estimatedPerServing.compareTo(b.estimatedPerServing);
  });
  return result;
});

String dietMatchType(Recipe recipe, String diet) {
  if (diet == 'Pescatarian') {
    return {'Vegan', 'Vegetarian', 'Pescatarian'}.any(recipe.tags.contains)
        ? 'exact'
        : 'none';
  }
  if (recipe.tags.contains(diet)) return 'exact';
  if (diet == 'Gluten-free' && glutenFreeSwaps(recipe).isNotEmpty) {
    return 'adaptable';
  }
  return 'none';
}

bool recipeFitsPreferences(Recipe recipe, DietaryPreferences preferences) {
  for (final diet in preferences.diets) {
    final match = dietMatchType(recipe, diet);
    if (match == 'none' || (preferences.exactMatches && match != 'exact')) {
      return false;
    }
  }
  if (preferences.allergies.any(recipe.allergens.contains)) return false;
  if (preferences.exactMatches &&
      preferences.goals.any((goal) => !recipe.tags.contains(goal))) {
    return false;
  }
  return true;
}

int recipeMatchScore(Recipe recipe, DietaryPreferences preferences) {
  final requested = [...preferences.diets, ...preferences.goals];
  if (requested.isEmpty) return 100;
  final matched = requested
      .where(
        (item) =>
            dietMatchType(recipe, item) != 'none' || recipe.tags.contains(item),
      )
      .length;
  return min(100, (70 + 30 * matched / requested.length).round());
}

List<IngredientSwap> glutenFreeSwaps(Recipe recipe) {
  if (recipe.tags.contains('Gluten-free')) return const [];
  final swaps = <IngredientSwap>[];
  for (final ingredient in recipe.ingredients) {
    final name = ingredient.name;
    if (RegExp('macaroni|pasta', caseSensitive: false).hasMatch(name)) {
      swaps.add(
        IngredientSwap(
          from: name,
          to: 'Gluten-free pasta',
          note: 'Choose rice, corn, or quinoa pasta.',
        ),
      );
    } else if (RegExp(r'\bflour\b', caseSensitive: false).hasMatch(name)) {
      swaps.add(
        IngredientSwap(
          from: name,
          to: '1-to-1 gluten-free flour',
          note: 'Use a labeled gluten-free baking blend.',
        ),
      );
    } else if (RegExp('noodle', caseSensitive: false).hasMatch(name)) {
      swaps.add(
        IngredientSwap(
          from: name,
          to: 'Rice noodles',
          note: 'Choose noodles labeled gluten-free.',
        ),
      );
    } else if (RegExp(
      r'\bbread\b|breadcrumbs?',
      caseSensitive: false,
    ).hasMatch(name)) {
      swaps.add(
        IngredientSwap(
          from: name,
          to: 'Gluten-free bread',
          note: 'Use certified gluten-free bread or crumbs.',
        ),
      );
    }
  }
  return swaps;
}

class AppController extends StateNotifier<AppState> {
  AppController({
    required this._storage,
    required this._dataRepository,
    required this._firebaseAuth,
    required this._firebaseAccounts,
  }) : super(const AppState());

  final LocalStorageService _storage;
  final AppDataRepository _dataRepository;
  final FirebaseAuthService _firebaseAuth;
  final FirebaseAccountRepository _firebaseAccounts;
  String? _firebaseUid;
  int _searchGeneration = 0;

  Future<void> initialize() async {
    try {
      final identity = await _firebaseAuth.currentIdentity();
      if (identity != null) {
        await _loadAccount(
          UserSession(
            username: identity.username,
            role: identity.isAdmin ? UserRole.admin : UserRole.member,
          ),
          firebaseUid: identity.uid,
        );
        return;
      }
    } catch (_) {
      // A stale Firebase session should not prevent the local login screen
      // from opening. The next explicit sign-in will show a useful error.
    }
    state = state.copyWith(initialized: true);
  }

  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw Exception('Enter an email and password.');
    }
    if (_firebaseAuth.isAvailable) {
      final identity = await _firebaseAuth.signIn(
        email: cleanEmail,
        password: password,
      );
      await _loadAccount(
        UserSession(
          username: identity.username,
          role: identity.isAdmin ? UserRole.admin : UserRole.member,
        ),
        firebaseUid: identity.uid,
      );
      await _persist();
      return;
    }

    // Keep local sign-in available for platforms that have not received a
    // native Firebase configuration yet (for example web/iOS in this build).
    final cleanName = cleanEmail;
    if (!_storage.accountExists(cleanName)) {
      throw Exception('Account not found. Create an account first.');
    }
    if (!_storage.verifyPassword(cleanName, password)) {
      throw Exception('Incorrect email or password.');
    }
    await _loadAccount(UserSession(username: cleanName, role: UserRole.member));
  }

  Future<void> createAccount(String email, String password) async {
    final cleanEmail = email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail)) {
      throw Exception('Enter a valid email address.');
    }
    if (password.length < 8) {
      throw Exception('Use at least an 8-character password.');
    }
    if (_firebaseAuth.isAvailable) {
      final identity = await _firebaseAuth.createAccount(
        email: cleanEmail,
        password: password,
      );
      await _loadAccount(
        UserSession(
          username: identity.username,
          role: identity.isAdmin ? UserRole.admin : UserRole.member,
        ),
        firebaseUid: identity.uid,
      );
      await _persist();
      return;
    }

    final created = await _storage.registerAccount(cleanEmail, password);
    if (!created) {
      throw Exception('That email is already in use. Try signing in.');
    }
    await _loadAccount(
      UserSession(username: cleanEmail, role: UserRole.member),
    );
  }

  void continueAsGuest() {
    _firebaseUid = null;
    _loadAccount(const UserSession(username: 'Guest', role: UserRole.guest));
  }

  Future<void> _loadAccount(UserSession session, {String? firebaseUid}) async {
    _firebaseUid = firebaseUid;
    StoredAccountState stored;
    if (firebaseUid == null) {
      stored = _storage.read(session.username);
    } else {
      try {
        stored = await _firebaseAccounts.read(firebaseUid);
      } catch (_) {
        // Authentication should still work if Firestore has not been created
        // yet or is temporarily unavailable; local storage is the offline
        // cache for that case.
        stored = _storage.read(session.username);
      }
    }
    state = AppState(
      initialized: true,
      session: session,
      preferences: stored.preferences,
      savedRecipeIds: stored.savedRecipeIds,
      plannedRecipes: stored.plannedRecipes,
      budgetItems: stored.budgetItems,
      weeklyBudget: stored.weeklyBudget,
      zipCode: stored.zipCode,
    );
  }

  void signOut() {
    _firebaseUid = null;
    _firebaseAuth.signOut();
    state = const AppState(initialized: true);
  }

  Future<void> _persist() async {
    final session = state.session;
    if (session == null || session.isGuest) return;
    final account = StoredAccountState(
      preferences: state.preferences,
      savedRecipeIds: state.savedRecipeIds,
      budgetItems: state.budgetItems,
      weeklyBudget: state.weeklyBudget,
      plannedRecipes: state.plannedRecipes,
      zipCode: state.zipCode,
    );
    if (_firebaseUid != null && _firebaseAccounts.isAvailable) {
      try {
        await _firebaseAccounts.write(uid: _firebaseUid!, account: account);
        return;
      } catch (_) {
        // Keep local caching as a resilient offline fallback.
      }
    }
    await _storage.write(
      username: session.username,
      preferences: account.preferences,
      savedRecipeIds: account.savedRecipeIds,
      budgetItems: account.budgetItems,
      weeklyBudget: account.weeklyBudget,
      plannedRecipes: account.plannedRecipes,
      zipCode: account.zipCode,
    );
  }

  void updatePreferences(DietaryPreferences preferences) {
    state = state.copyWith(preferences: preferences);
    _persist();
  }

  void toggleSaved(String recipeId) {
    final next = {...state.savedRecipeIds};
    next.contains(recipeId) ? next.remove(recipeId) : next.add(recipeId);
    state = state.copyWith(savedRecipeIds: next);
    _persist();
  }

  void addToPlan(Recipe recipe) {
    if (state.plannedRecipes.any((item) => item.recipeId == recipe.id)) return;
    final swaps = state.preferences.diets.contains('Gluten-free')
        ? glutenFreeSwaps(recipe)
        : const <IngredientSwap>[];
    state = state.copyWith(
      plannedRecipes: [
        ...state.plannedRecipes,
        PlannedRecipe(
          recipeId: recipe.id,
          servings: recipe.servings,
          ingredientOverrides: {for (final swap in swaps) swap.from: swap.to},
        ),
      ],
    );
    _persist();
  }

  void clearPlan() {
    state = state.copyWith(clearPlan: true);
    _persist();
  }

  void removeFromPlan(String recipeId) {
    state = state.copyWith(
      plannedRecipes: state.plannedRecipes
          .where((item) => item.recipeId != recipeId)
          .toList(),
    );
    _persist();
  }

  void setPlanServings(String recipeId, int servings) {
    final nextServings = servings.clamp(1, 24).toInt();
    state = state.copyWith(
      plannedRecipes: [
        for (final planned in state.plannedRecipes)
          planned.recipeId == recipeId
              ? planned.copyWith(servings: nextServings)
              : planned,
      ],
    );
    _persist();
  }

  List<Ingredient> effectiveIngredients(
    Recipe recipe, {
    PlannedRecipe? planned,
  }) {
    final entry = planned ?? _plannedRecipeFor(recipe.id);
    if (entry == null) return recipe.ingredients;
    return recipe.ingredients
        .map(
          (item) => item.copyWith(
            name: entry.ingredientOverrides[item.name],
            quantity: scaleIngredientQuantity(
              item.quantity,
              originalServings: recipe.servings,
              targetServings: entry.servings,
            ),
          ),
        )
        .toList();
  }

  PlannedRecipe? _plannedRecipeFor(String recipeId) {
    for (final planned in state.plannedRecipes) {
      if (planned.recipeId == recipeId) return planned;
    }
    return null;
  }

  void clearRecipeSearch() {
    _searchGeneration++;
    state = state.copyWith(
      recipes: seedRecipes,
      searchingRecipes: false,
      clearSearchError: true,
      activeSearchQuery: '',
    );
  }

  Future<void> searchRecipes(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      clearRecipeSearch();
      return;
    }
    final generation = ++_searchGeneration;
    state = state.copyWith(
      searchingRecipes: true,
      clearSearchError: true,
      activeSearchQuery: cleanQuery,
    );
    try {
      final found = await _dataRepository.searchRecipes(cleanQuery);
      if (generation != _searchGeneration) return;
      state = state.copyWith(
        recipes: [...seedRecipes, ...found],
        searchingRecipes: false,
        activeSearchQuery: cleanQuery,
      );
    } catch (error) {
      if (generation != _searchGeneration) return;
      state = state.copyWith(searchingRecipes: false, searchError: '$error');
    }
  }

  Future<void> locateByZip(String zip) async {
    if (!RegExp(r'^\d{5}$').hasMatch(zip)) {
      state = state.copyWith(
        loadingStores: false,
        storeError: 'Enter a valid 5-digit ZIP code.',
      );
      throw const DataLayerException('Enter a valid 5-digit ZIP code.');
    }
    state = state.copyWith(loadingStores: true, clearStoreError: true);
    try {
      final result = await _dataRepository.searchStoresByZip(zip);
      await _applyStores(
        center: result.center,
        stores: result.stores,
        zip: zip,
      );
    } catch (error) {
      state = state.copyWith(loadingStores: false, storeError: '$error');
      rethrow;
    }
  }

  Future<void> useCurrentLocation() async {
    state = state.copyWith(loadingStores: true, clearStoreError: true);
    try {
      final result = await _dataRepository.searchStoresAtCurrentLocation();
      await _applyStores(center: result.center, stores: result.stores);
    } catch (error) {
      state = state.copyWith(loadingStores: false, storeError: '$error');
      rethrow;
    }
  }

  Future<void> _applyStores({
    required LatLng center,
    required List<GroceryStore> stores,
    String? zip,
  }) async {
    final selectedId = stores.isEmpty ? null : stores.first.id;
    state = state.copyWith(
      userLocation: center,
      stores: stores,
      selectedStoreId: selectedId,
      zipCode: zip,
      clearZipCode: zip == null,
      loadingStores: false,
      taxIsManual: false,
    );
    if (selectedId != null) await _updateTaxForSelectedStore();
    _persist();
  }

  Future<void> selectStore(String storeId) async {
    state = state.copyWith(selectedStoreId: storeId, taxIsManual: false);
    await _updateTaxForSelectedStore();
  }

  Future<void> _updateTaxForSelectedStore() async {
    final store = state.selectedStore;
    if (store == null) return;
    state = state.copyWith(loadingTax: true, clearTaxError: true);
    final estimate = await _dataRepository.estimateTax(store);
    state = state.copyWith(
      loadingTax: false,
      taxRate: estimate.rate,
      taxIsManual: false,
      taxError: estimate.rate == 0 ? estimate.label : null,
      clearTaxError: estimate.rate != 0,
    );
  }

  void setManualTax(double value) => state = state.copyWith(
    taxRate: value.clamp(0, 20).toDouble(),
    taxIsManual: true,
  );

  Future<void> restoreAutomaticTax() => _updateTaxForSelectedStore();

  void importPlanToBudget() {
    final existing = state.budgetItems
        .map((item) => item.name.toLowerCase())
        .toSet();
    final additions = <BudgetItem>[];
    final multipleRecipes = state.plannedRecipes.length > 1;
    for (final planned in state.plannedRecipes) {
      final matches = state.planRecipes.where(
        (item) => item.id == planned.recipeId,
      );
      if (matches.isEmpty) continue;
      final recipe = matches.first;
      for (final item in effectiveIngredients(recipe, planned: planned)) {
        final name = multipleRecipes
            ? '${item.name} · ${item.quantity} · ${recipe.name}'
            : '${item.name} · ${item.quantity}';
        if (existing.contains(name.toLowerCase())) continue;
        existing.add(name.toLowerCase());
        additions.add(
          BudgetItem(
            id: '${DateTime.now().microsecondsSinceEpoch}-${item.name}',
            name: name,
          ),
        );
      }
    }
    if (additions.isEmpty) return;
    state = state.copyWith(budgetItems: [...state.budgetItems, ...additions]);
    _persist();
  }

  void addBudgetItem() {
    state = state.copyWith(
      budgetItems: [
        ...state.budgetItems,
        BudgetItem(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          name: 'New grocery item',
        ),
      ],
    );
    _persist();
  }

  void updateBudgetItem(BudgetItem item) {
    state = state.copyWith(
      budgetItems: [
        for (final existing in state.budgetItems)
          if (existing.id == item.id) item else existing,
      ],
    );
    _persist();
  }

  void removeBudgetItem(String id) {
    state = state.copyWith(
      budgetItems: state.budgetItems.where((item) => item.id != id).toList(),
    );
    _persist();
  }

  void setWeeklyBudget(double value) {
    state = state.copyWith(weeklyBudget: max(0, value));
    _persist();
  }
}
