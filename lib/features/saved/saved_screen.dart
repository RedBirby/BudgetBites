import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import '../discover/recipe_card.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final recipes = state.recipes
        .where((item) => state.savedRecipeIds.contains(item.id))
        .toList();
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'Your collection',
            title: 'Saved recipes',
            subtitle:
                'Recipes saved in this account stay separate from every other account.',
          ),
          const SizedBox(height: 20),
          if (recipes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 44,
                        color: AppColors.green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No saved recipes yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap the bookmark on a recipe to keep it here for later.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      _DiscoverButton(),
                    ],
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 600
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

class _DiscoverButton extends StatelessWidget {
  const _DiscoverButton();

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => context.go('/discover'),
    icon: const Icon(Icons.explore_outlined),
    label: const Text('Browse recipes'),
  );
}
