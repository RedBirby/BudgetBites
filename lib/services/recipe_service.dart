import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/recipe.dart';

class RecipeService {
  RecipeService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Recipe>> search(String query) async {
    final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/search.php', {
      's': query,
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Recipe search is unavailable.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['meals'] as List? ?? const []).map((raw) {
      final meal = Map<String, dynamic>.from(raw as Map);
      final ingredients = <Ingredient>[];
      for (var index = 1; index <= 20; index++) {
        final name = (meal['strIngredient$index'] as String? ?? '').trim();
        final quantity = (meal['strMeasure$index'] as String? ?? '').trim();
        if (name.isNotEmpty) {
          ingredients.add(
            Ingredient(
              name: name,
              quantity: quantity.isEmpty ? 'As needed' : quantity,
            ),
          );
        }
      }
      final text = ingredients.map((item) => item.name).join(' ').toLowerCase();
      final landMeat = RegExp(
        'chicken|beef|pork|lamb|turkey|duck|bacon|sausage|ham',
      );
      final seafood = RegExp(
        'fish|salmon|tuna|anchov|prawn|shrimp|crab|lobster|clam|mussel|oyster',
      );
      final animal = RegExp('milk|cream|cheese|butter|egg|honey|yogurt');
      final gluten = RegExp(
        'bread|flour|pasta|noodle|couscous|barley|wheat|macaroni',
      );
      final tags = <String>{};
      if (!landMeat.hasMatch(text)) tags.add('Pescatarian');
      if (!landMeat.hasMatch(text) && !seafood.hasMatch(text)) {
        tags.add('Vegetarian');
      }
      if (!landMeat.hasMatch(text) &&
          !seafood.hasMatch(text) &&
          !animal.hasMatch(text)) {
        tags.add('Vegan');
      }
      if (!gluten.hasMatch(text)) tags.add('Gluten-free');
      if (RegExp(
        'bean|lentil|chickpea|tofu|chicken|beef|fish|salmon|tuna|egg',
      ).hasMatch(text)) {
        tags.add('High protein');
      }
      final allergens = <String>{};
      if (text.contains('peanut')) allergens.add('Peanuts');
      if (RegExp(
        'almond|cashew|walnut|pecan|pistachio|hazelnut',
      ).hasMatch(text)) {
        allergens.add('Tree nuts');
      }
      if (RegExp('milk|cream|cheese|butter|yogurt|whey').hasMatch(text)) {
        allergens.add('Dairy');
      }
      if (RegExp(r'\begg').hasMatch(text)) allergens.add('Eggs');
      if (RegExp(
        'prawn|shrimp|crab|lobster|clam|mussel|oyster',
      ).hasMatch(text)) {
        allergens.add('Shellfish');
      }
      if (RegExp(r'\bsoy|tofu|tempeh|edamame|miso').hasMatch(text)) {
        allergens.add('Soy');
      }
      return Recipe(
        id: 'mealdb-${meal['idMeal']}',
        name: meal['strMeal'] as String,
        imageUrl: meal['strMealThumb'] as String? ?? '',
        minutes: 30,
        servings: 4,
        estimatedPerServing: (ingredients.length * .32)
            .clamp(1.75, 5.5)
            .toDouble(),
        tags: tags,
        allergens: allergens,
        ingredients: ingredients,
        sourceUrl: Uri.tryParse(meal['strSource'] as String? ?? ''),
      );
    }).toList();
  }
}
