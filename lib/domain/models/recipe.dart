class Ingredient {
  const Ingredient({required this.name, required this.quantity});
  final String name;
  final String quantity;
  Ingredient copyWith({String? name, String? quantity}) =>
      Ingredient(name: name ?? this.name, quantity: quantity ?? this.quantity);
}

class IngredientSwap {
  const IngredientSwap({
    required this.from,
    required this.to,
    required this.note,
  });
  final String from;
  final String to;
  final String note;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.minutes,
    required this.servings,
    required this.estimatedPerServing,
    required this.tags,
    required this.ingredients,
    this.allergens = const {},
    this.sourceUrl,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int minutes;
  final int servings;
  final double estimatedPerServing;
  final Set<String> tags;
  final Set<String> allergens;
  final List<Ingredient> ingredients;
  final Uri? sourceUrl;

  String get normalizedName => name
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .trim();
}
