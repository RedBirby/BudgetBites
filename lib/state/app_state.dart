import 'package:latlong2/latlong.dart';

import '../data/seed_data.dart';
import '../domain/models/budget_item.dart';
import '../domain/models/dietary_preferences.dart';
import '../domain/models/grocery_store.dart';
import '../domain/models/planned_recipe.dart';
import '../domain/models/recipe.dart';
import '../domain/models/user_session.dart';

class AppState {
  const AppState({
    this.initialized = false,
    this.session,
    this.preferences = const DietaryPreferences(),
    this.recipes = seedRecipes,
    this.savedRecipeIds = const {},
    this.plannedRecipes = const [],
    this.zipCode,
    this.userLocation,
    this.stores = const [],
    this.selectedStoreId,
    this.loadingStores = false,
    this.storeError,
    this.searchingRecipes = false,
    this.searchError,
    this.activeSearchQuery = '',
    this.budgetItems = const [],
    this.weeklyBudget = 100,
    this.taxRate = 0,
    this.taxIsManual = false,
  });

  final bool initialized;
  final UserSession? session;
  final DietaryPreferences preferences;
  final List<Recipe> recipes;
  final Set<String> savedRecipeIds;
  final List<PlannedRecipe> plannedRecipes;
  final String? zipCode;
  final LatLng? userLocation;
  final List<GroceryStore> stores;
  final String? selectedStoreId;
  final bool loadingStores;
  final String? storeError;
  final bool searchingRecipes;
  final String? searchError;
  final String activeSearchQuery;
  final List<BudgetItem> budgetItems;
  final double weeklyBudget;
  final double taxRate;
  final bool taxIsManual;

  List<Recipe> get planRecipes => [
    for (final planned in plannedRecipes)
      for (final recipe in recipes)
        if (recipe.id == planned.recipeId) recipe,
  ];

  Recipe? get planRecipe =>
      _recipeFor(plannedRecipes.isEmpty ? null : plannedRecipes.first.recipeId);

  Recipe? _recipeFor(String? recipeId) {
    if (recipeId == null) return null;
    for (final recipe in recipes) {
      if (recipe.id == recipeId) return recipe;
    }
    return null;
  }

  GroceryStore? get selectedStore {
    for (final store in stores) {
      if (store.id == selectedStoreId) return store;
    }
    return null;
  }

  double get subtotal =>
      budgetItems.fold(0, (sum, item) => sum + (item.price ?? 0));
  double get tax => subtotal * taxRate / 100;
  double get checkoutTotal => subtotal + tax;

  AppState copyWith({
    bool? initialized,
    UserSession? session,
    bool clearSession = false,
    DietaryPreferences? preferences,
    List<Recipe>? recipes,
    Set<String>? savedRecipeIds,
    bool clearPlan = false,
    List<PlannedRecipe>? plannedRecipes,
    String? zipCode,
    bool clearZipCode = false,
    LatLng? userLocation,
    List<GroceryStore>? stores,
    String? selectedStoreId,
    bool? loadingStores,
    String? storeError,
    bool clearStoreError = false,
    bool? searchingRecipes,
    String? searchError,
    bool clearSearchError = false,
    String? activeSearchQuery,
    List<BudgetItem>? budgetItems,
    double? weeklyBudget,
    double? taxRate,
    bool? taxIsManual,
  }) => AppState(
    initialized: initialized ?? this.initialized,
    session: clearSession ? null : session ?? this.session,
    preferences: preferences ?? this.preferences,
    recipes: recipes ?? this.recipes,
    savedRecipeIds: savedRecipeIds ?? this.savedRecipeIds,
    plannedRecipes: clearPlan
        ? const []
        : plannedRecipes ?? this.plannedRecipes,
    zipCode: clearZipCode ? null : zipCode ?? this.zipCode,
    userLocation: userLocation ?? this.userLocation,
    stores: stores ?? this.stores,
    selectedStoreId: selectedStoreId ?? this.selectedStoreId,
    loadingStores: loadingStores ?? this.loadingStores,
    storeError: clearStoreError ? null : storeError ?? this.storeError,
    searchingRecipes: searchingRecipes ?? this.searchingRecipes,
    searchError: clearSearchError ? null : searchError ?? this.searchError,
    activeSearchQuery: activeSearchQuery ?? this.activeSearchQuery,
    budgetItems: budgetItems ?? this.budgetItems,
    weeklyBudget: weeklyBudget ?? this.weeklyBudget,
    taxRate: taxRate ?? this.taxRate,
    taxIsManual: taxIsManual ?? this.taxIsManual,
  );
}
