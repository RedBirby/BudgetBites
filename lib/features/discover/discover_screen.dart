import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import 'recipe_card.dart';
import 'welcome_panel.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      appControllerProvider.select((state) => state.activeSearchQuery),
      (previous, next) {
        if ((previous?.isNotEmpty ?? false) && next.isEmpty) {
          _search.clear();
        }
      },
    );
    final state = ref.watch(appControllerProvider);
    final recipes = ref.watch(visibleRecipesProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'Personalized for you',
            title: 'Eat well on your budget',
            subtitle:
                'Search live recipes, filter dietary needs, and turn one recipe into a practical grocery trip.',
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SearchBar(
              controller: _search,
              hintText: 'Search recipes or ingredients',
              leading: const Icon(Icons.search),
              trailing: [
                FilledButton(
                  onPressed: () => controller.searchRecipes(_search.text),
                  child: const Text('Search'),
                ),
              ],
              onSubmitted: controller.searchRecipes,
            ),
          ),
          if (state.activeSearchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            const HelpfulHint(
              text:
                  'Tip: choose a recipe, tap Add to plan, then set servings and pick a store.',
            ),
            const SizedBox(height: 18),
            const WelcomePanel(),
          ],
          if (!state.preferences.isEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: [
                ...state.preferences.diets.map(PreferenceChip.new),
                ...state.preferences.allergies.map(
                  (item) =>
                      PreferenceChip('$item-free', icon: Icons.shield_outlined),
                ),
                ...state.preferences.goals.map(
                  (item) => PreferenceChip(item, tone: AppColors.cream),
                ),
              ],
            ),
          ],
          if (state.searchingRecipes)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: LinearProgressIndicator(),
            ),
          if (state.searchError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.searchError!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            state.activeSearchQuery.isEmpty
                ? 'Recipes that match your goals'
                : 'Results for “${state.activeSearchQuery}”',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (recipes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 42,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No recipes found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try a different ingredient, or loosen a preference to see more options.',
                        textAlign: TextAlign.center,
                      ),
                      if (state.activeSearchQuery.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: controller.clearRecipeSearch,
                          icon: const Icon(Icons.close),
                          label: const Text('Clear search'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 650
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 18) / columns;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final recipe in recipes)
                      SizedBox(
                        width: width,
                        child: RecipeCard(recipe: recipe),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
