class PlannedRecipe {
  const PlannedRecipe({
    required this.recipeId,
    required this.servings,
    this.ingredientOverrides = const {},
  });

  final String recipeId;
  final int servings;
  final Map<String, String> ingredientOverrides;

  PlannedRecipe copyWith({
    String? recipeId,
    int? servings,
    Map<String, String>? ingredientOverrides,
  }) => PlannedRecipe(
    recipeId: recipeId ?? this.recipeId,
    servings: servings ?? this.servings,
    ingredientOverrides: ingredientOverrides ?? this.ingredientOverrides,
  );

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'servings': servings,
    'ingredientOverrides': ingredientOverrides,
  };

  factory PlannedRecipe.fromJson(Map<String, dynamic> json) => PlannedRecipe(
    recipeId: json['recipeId'] as String,
    servings: (json['servings'] as num?)?.toInt() ?? 1,
    ingredientOverrides: Map<String, String>.from(
      json['ingredientOverrides'] as Map? ?? const {},
    ),
  );
}
