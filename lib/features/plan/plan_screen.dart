import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import 'location_confirmation.dart';
import 'location_gate.dart';
import 'recipe_plan_card.dart';
import 'stores_card.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    if (state.userLocation == null || state.stores.isEmpty) {
      return const PageContainer(child: LocationGate());
    }
    final plannedRecipes = state.plannedRecipes;
    final controller = ref.read(appControllerProvider.notifier);
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            eyebrow: 'Your grocery run',
            title: 'Build the best basket',
            subtitle:
                'Compare nearby stores, review ingredients, and open retailer product searches.',
            trailing: OutlinedButton.icon(
              onPressed: controller.clearPlan,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear plan'),
            ),
          ),
          const SizedBox(height: 16),
          LocationConfirmation(
            zipCode: state.zipCode,
            storeCount: state.stores.length,
          ),
          const SizedBox(height: 10),
          const HelpfulHint(
            text:
                'Tip: adjust servings, check your ingredients, then tap a store below. A confirmation popup will guide you next.',
          ),
          const SizedBox(height: 22),
          if (plannedRecipes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(42),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 48,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No recipe in your plan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Choose a recipe from Discover to create an ingredient checklist.',
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // A phone in landscape is often only ~760 logical pixels
                // wide. Split the checklist and store browser at that point.
                final wide = constraints.maxWidth >= 760;
                final recipeCards = <Widget>[];
                String? firstIngredient;
                for (final planned in plannedRecipes) {
                  final matches = state.planRecipes.where(
                    (item) => item.id == planned.recipeId,
                  );
                  if (matches.isEmpty) continue;
                  final recipe = matches.first;
                  final ingredients = controller.effectiveIngredients(
                    recipe,
                    planned: planned,
                  );
                  firstIngredient ??= ingredients.isEmpty
                      ? null
                      : ingredients.first.name;
                  recipeCards.add(
                    RecipePlanCard(
                      recipeName: recipe.name,
                      minutes: recipe.minutes,
                      servings: planned.servings,
                      ingredients: ingredients,
                      store: state.selectedStore,
                      onServings: (value) =>
                          controller.setPlanServings(recipe.id, value),
                      onRemove: () => controller.removeFromPlan(recipe.id),
                    ),
                  );
                }
                if (recipeCards.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(42),
                      child: Center(
                        child: Text(
                          'Choose a recipe from Discover to continue.',
                        ),
                      ),
                    ),
                  );
                }
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var index = 0;
                      index < recipeCards.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(height: 18),
                      recipeCards[index],
                    ],
                  ],
                );
                final right = StoresCard(
                  stores: state.stores,
                  center: state.userLocation!,
                  selectedId: state.selectedStoreId,
                  searchIngredient: firstIngredient,
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 18),
                          Expanded(child: right),
                        ],
                      )
                    : Column(
                        children: [left, const SizedBox(height: 18), right],
                      );
              },
            ),
        ],
      ),
    );
  }
}
