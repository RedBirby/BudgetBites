import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/grocery_store.dart';
import '../../domain/models/recipe.dart';
import '../../services/retailer_link_service.dart';
import 'plan_links.dart';

class RecipePlanCard extends StatelessWidget {
  const RecipePlanCard({
    required this.recipeName,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.store,
    required this.onServings,
    required this.onRemove,
    super.key,
  });

  final String recipeName;
  final int minutes;
  final int servings;
  final List<Ingredient> ingredients;
  final GroceryStore? store;
  final ValueChanged<int> onServings;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final links = RetailerLinkService();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'SELECTED RECIPE',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Remove'),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(recipeName, style: Theme.of(context).textTheme.headlineMedium),
            Text(
              'Recipe takes about $minutes minutes to make',
              style: const TextStyle(color: AppColors.muted),
            ),
            const Divider(height: 30),
            LayoutBuilder(
              builder: (context, constraints) {
                const servingCopy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How many servings?',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Ingredient quantities scale with this count.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                );
                final controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      onPressed: servings > 1
                          ? () => onServings(servings - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$servings',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () => onServings(servings + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                );
                return constraints.maxWidth < 420
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          servingCopy,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: controls,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: servingCopy),
                          controls,
                        ],
                      );
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Ingredient checklist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            for (final ingredient in ingredients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(value: true, onChanged: (_) {}),
                title: Text(
                  ingredient.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(ingredient.quantity),
                trailing: store == null
                    ? null
                    : IconButton(
                        tooltip: 'Check at ${store!.name}',
                        icon: const Icon(
                          Icons.open_in_new,
                          color: AppColors.green,
                        ),
                        onPressed: () async {
                          final uri = links.productSearch(
                            store!,
                            ingredient.name,
                          );
                          if (uri != null) {
                            await launchExternalLink(
                              context,
                              uri,
                              failureMessage:
                                  'This retailer link could not be opened.',
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${store!.name} does not list a website or online inventory.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
