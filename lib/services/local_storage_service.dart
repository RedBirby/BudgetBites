import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/budget_item.dart';
import '../domain/models/dietary_preferences.dart';
import '../domain/models/planned_recipe.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden'),
);

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(ref.watch(sharedPreferencesProvider)),
);

class StoredAccountState {
  const StoredAccountState({
    required this.preferences,
    required this.savedRecipeIds,
    required this.budgetItems,
    required this.weeklyBudget,
    this.plannedRecipes = const [],
    this.zipCode,
  });
  final DietaryPreferences preferences;
  final Set<String> savedRecipeIds;
  final List<BudgetItem> budgetItems;
  final double weeklyBudget;
  final List<PlannedRecipe> plannedRecipes;
  final String? zipCode;
}

class LocalStorageService {
  LocalStorageService(this._preferences);
  final SharedPreferences _preferences;

  static const _accountsStorageKey = 'budgetbite.accounts.v1';

  String _key(String username) =>
      'budgetbite.account.${username.toLowerCase()}';

  Map<String, String> _readAccounts() {
    final raw = _preferences.getString(_accountsStorageKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key.toLowerCase(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  String _passwordDigest(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  bool accountExists(String username) {
    final normalized = username.trim().toLowerCase();
    return normalized.isNotEmpty && _readAccounts().containsKey(normalized);
  }

  bool verifyPassword(String username, String password) {
    final normalized = username.trim().toLowerCase();
    final savedDigest = _readAccounts()[normalized];
    return savedDigest != null && savedDigest == _passwordDigest(password);
  }

  Future<bool> registerAccount(String username, String password) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || _readAccounts().containsKey(normalized)) {
      return false;
    }
    final accounts = _readAccounts()..[normalized] = _passwordDigest(password);
    final saved = await _preferences.setString(
      _accountsStorageKey,
      jsonEncode(accounts),
    );
    return saved;
  }

  StoredAccountState read(String username) {
    final raw = _preferences.getString(_key(username));
    if (raw == null) {
      return const StoredAccountState(
        preferences: DietaryPreferences(),
        savedRecipeIds: {},
        budgetItems: [],
        weeklyBudget: 100,
      );
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return StoredAccountState(
        preferences: DietaryPreferences.fromJson(
          Map<String, dynamic>.from(json['preferences'] as Map? ?? const {}),
        ),
        savedRecipeIds: Set<String>.from(
          json['savedRecipeIds'] as List? ?? const [],
        ),
        budgetItems: (json['budgetItems'] as List? ?? const [])
            .map(
              (item) =>
                  BudgetItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        weeklyBudget: (json['weeklyBudget'] as num?)?.toDouble() ?? 100,
        plannedRecipes: _readPlannedRecipes(json),
        zipCode: json['zipCode'] as String?,
      );
    } catch (_) {
      return const StoredAccountState(
        preferences: DietaryPreferences(),
        savedRecipeIds: {},
        budgetItems: [],
        weeklyBudget: 100,
      );
    }
  }

  Future<void> write({
    required String username,
    required DietaryPreferences preferences,
    required Set<String> savedRecipeIds,
    required List<BudgetItem> budgetItems,
    required double weeklyBudget,
    String? planRecipeId,
    List<PlannedRecipe> plannedRecipes = const [],
    String? zipCode,
  }) => _preferences.setString(
    _key(username),
    jsonEncode({
      'preferences': preferences.toJson(),
      'savedRecipeIds': savedRecipeIds.toList(),
      'budgetItems': budgetItems.map((item) => item.toJson()).toList(),
      'weeklyBudget': weeklyBudget,
      'plannedRecipes': plannedRecipes.map((item) => item.toJson()).toList(),
      // Keep the legacy key for older builds that may still read this account.
      'planRecipeId': plannedRecipes.isEmpty
          ? planRecipeId
          : plannedRecipes.first.recipeId,
      'zipCode': zipCode,
    }),
  );

  static List<PlannedRecipe> _readPlannedRecipes(Map<String, dynamic> json) {
    final raw = json['plannedRecipes'] as List?;
    if (raw != null) {
      return raw
          .map(
            (item) =>
                PlannedRecipe.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    final legacyId = json['planRecipeId'] as String?;
    return legacyId == null
        ? const []
        : [PlannedRecipe(recipeId: legacyId, servings: 4)];
  }
}
