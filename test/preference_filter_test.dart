import 'package:budgetbite_app/data/seed_data.dart';
import 'package:budgetbite_app/domain/models/dietary_preferences.dart';
import 'package:budgetbite_app/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dietary recipe filtering', () {
    test('vegan preferences exclude dairy and fish recipes', () {
      const preferences = DietaryPreferences(diets: {'Vegan'});
      final matches = seedRecipes.where(
        (recipe) => recipeFitsPreferences(recipe, preferences),
      );
      expect(matches, isNotEmpty);
      expect(matches.every((recipe) => recipe.tags.contains('Vegan')), isTrue);
    });

    test('gluten-free preferences keep adaptable pasta when exact is off', () {
      const preferences = DietaryPreferences(diets: {'Gluten-free'});
      final pasta = seedRecipes.firstWhere((recipe) => recipe.id == 'pasta');
      expect(recipeFitsPreferences(pasta, preferences), isTrue);
      expect(glutenFreeSwaps(pasta), isNotEmpty);
    });

    test('exact gluten-free preferences remove adaptable pasta', () {
      const preferences = DietaryPreferences(
        diets: {'Gluten-free'},
        exactMatches: true,
      );
      final pasta = seedRecipes.firstWhere((recipe) => recipe.id == 'pasta');
      expect(recipeFitsPreferences(pasta, preferences), isFalse);
    });
  });

  group('recipe search ranking', () {
    test('exact title matches rank above unrelated recipes', () {
      final pasta = seedRecipes.firstWhere((recipe) => recipe.id == 'pasta');
      final curry = seedRecipes.firstWhere((recipe) => recipe.id == 'curry');

      expect(
        recipeSearchRelevance(pasta, 'Tomato garlic pasta'),
        greaterThan(recipeSearchRelevance(curry, 'Tomato garlic pasta')),
      );
      expect(
        recipeSearchRelevance(pasta, 'Tomato garlic pasta'),
        greaterThanOrEqualTo(1000),
      );
    });

    test('ingredient searches include recipes containing that ingredient', () {
      final pasta = seedRecipes.firstWhere((recipe) => recipe.id == 'pasta');
      expect(recipeSearchRelevance(pasta, 'tomato'), greaterThan(0));
    });
  });
}
