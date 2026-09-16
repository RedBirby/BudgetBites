import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import 'recipe_card.dart';

const _heroImageUrl =
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=85';

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
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .searchRecipes(_search.text),
                  child: const Text('Search'),
                ),
              ],
              onSubmitted: (value) =>
                  ref.read(appControllerProvider.notifier).searchRecipes(value),
            ),
          ),
          if (state.activeSearchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            const HelpfulHint(
              text:
                  'Tip: choose a recipe, tap Add to plan, then set servings and pick a store.',
            ),
          ],
          if (state.activeSearchQuery.isEmpty) ...[
            const SizedBox(height: 18),
            const _WelcomePanel(),
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
                          onPressed: () => ref
                              .read(appControllerProvider.notifier)
                              .clearRecipeSearch(),
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

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.mint,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final copy = Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'A little inspiration',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Good food, lighter budget.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Pick a recipe, check nearby prices, and make a grocery plan that fits your life.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: const [
                    PreferenceChip(
                      'Budget-friendly',
                      icon: Icons.savings_outlined,
                    ),
                    PreferenceChip(
                      'Wellness-minded',
                      icon: Icons.favorite_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/preferences'),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Set preferences'),
                ),
              ],
            ),
          );
          const hero = _HeroImage(
            imageUrl: _heroImageUrl,
            title: 'Fresh ingredients, smarter shopping',
            subtitle: 'Plan meals that fit your budget.',
          );
          return Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [copy, const SizedBox(height: 6), hero],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 18),
                      SizedBox(width: 330, child: hero),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: AspectRatio(
      aspectRatio: 1.12,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RecipeImage(source: imageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC152019)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
