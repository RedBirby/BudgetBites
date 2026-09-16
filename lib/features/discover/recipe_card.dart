import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/recipe.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({required this.source, this.fit = BoxFit.cover, super.key});

  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('asset:')) {
      return Image.asset(
        source.substring('asset:'.length),
        fit: fit,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: AppColors.mint,
          child: Icon(Icons.restaurant, size: 42),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      placeholder: (_, _) => const ColoredBox(
        color: AppColors.mint,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.mint,
        child: Icon(Icons.restaurant, size: 42),
      ),
    );
  }
}

class RecipeCard extends ConsumerWidget {
  const RecipeCard({required this.recipe, super.key});
  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final saved = state.savedRecipeIds.contains(recipe.id);
    final inPlan = state.plannedRecipes.any(
      (planned) => planned.recipeId == recipe.id,
    );
    final swaps = state.preferences.diets.contains('Gluten-free')
        ? glutenFreeSwaps(recipe)
        : const <IngredientSwap>[];
    final chips = <Widget>[];
    for (final diet in state.preferences.diets) {
      final type = dietMatchType(recipe, diet);
      if (type != 'none') {
        chips.add(
          PreferenceChip(
            type == 'adaptable' ? '$diet with swaps' : diet,
            icon: type == 'adaptable' ? Icons.sync : Icons.check,
          ),
        );
      }
    }
    for (final allergy in state.preferences.allergies) {
      if (!recipe.allergens.contains(allergy)) {
        chips.add(PreferenceChip('$allergy-free', icon: Icons.shield_outlined));
      }
    }
    for (final goal in state.preferences.goals) {
      if (recipe.tags.contains(goal)) {
        chips.add(PreferenceChip(goal, tone: AppColors.cream));
      }
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: RecipeImage(source: recipe.imageUrl),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: IconButton.filledTonal(
                  tooltip: saved ? 'Remove from saved' : 'Save recipe',
                  onPressed: () => controller.toggleSaved(recipe.id),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Text(
                          '\$${recipe.estimatedPerServing.toStringAsFixed(2)} / serving',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!state.preferences.isEmpty)
                      Text(
                        '${recipeMatchScore(recipe, state.preferences)}% match',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 17,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'About ${recipe.minutes} min',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.people_outline,
                      size: 17,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${recipe.servings} servings',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'MATCHES YOUR PREFERENCES',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: .5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(spacing: 6, runSpacing: 4, children: chips),
                ],
                if (swaps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EF),
                      border: Border.all(color: const Color(0xFFEDCFAA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.route,
                          color: AppColors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gluten-free route: ${swaps.map((swap) => 'use ${swap.to} instead of ${swap.from}').join(' · ')}. Verify cheese and sauce labels.',
                            style: const TextStyle(fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.toggleSaved(recipe.id),
                        child: Text(saved ? 'Saved' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          controller.addToPlan(recipe);
                          context.go('/plan');
                        },
                        child: Text(
                          inPlan
                              ? 'In plan'
                              : (swaps.isEmpty
                                    ? 'Add to plan'
                                    : 'Use swaps & add'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
