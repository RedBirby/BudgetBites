import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/grocery_store.dart';
import '../../domain/models/recipe.dart';
import '../../services/retailer_link_service.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import 'location_gate.dart';

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
          _LocationConfirmation(
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
                final wide = constraints.maxWidth >= 850;
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
                    _RecipePlanCard(
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
                final right = _StoresCard(
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

class _LocationConfirmation extends StatelessWidget {
  const _LocationConfirmation({
    required this.zipCode,
    required this.storeCount,
  });

  final String? zipCode;
  final int storeCount;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.mint,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, color: AppColors.green, size: 31),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.greenDark,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location received',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  zipCode == null
                      ? 'Showing stores near your approximate current location.'
                      : 'Showing stores near ZIP $zipCode.',
                  style: const TextStyle(color: AppColors.ink, height: 1.35),
                ),
                const SizedBox(height: 3),
                Text(
                  '$storeCount nearby ${storeCount == 1 ? 'store' : 'stores'} found',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: AppColors.green, size: 24),
        ],
      ),
    ),
  );
}

class _RecipePlanCard extends StatelessWidget {
  const _RecipePlanCard({
    required this.recipeName,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.store,
    required this.onServings,
    required this.onRemove,
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
            Row(
              children: [
                const Expanded(
                  child: Column(
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
                  ),
                ),
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
                            final opened = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This retailer link could not be opened.',
                                  ),
                                ),
                              );
                            }
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

Uri _directionsUri(GroceryStore store) =>
    Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': '${store.location.latitude},${store.location.longitude}',
    });

class _StoresCard extends ConsumerWidget {
  const _StoresCard({
    required this.stores,
    required this.center,
    required this.selectedId,
    required this.searchIngredient,
  });
  final List<GroceryStore> stores;
  final LatLng center;
  final String? selectedId;
  final String? searchIngredient;

  Future<void> _selectStore(
    BuildContext context,
    WidgetRef ref,
    GroceryStore store,
  ) async {
    await ref.read(appControllerProvider.notifier).selectStore(store.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const CircleAvatar(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.green,
          child: Icon(Icons.check),
        ),
        title: Text('${store.name} selected'),
        content: Text(
          'Your ingredient list is ready. Take it with you and check each item as you shop at ${store.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep planning'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final opened = await launchUrl(
                _directionsUri(store),
                mode: LaunchMode.externalApplication,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Directions could not be opened.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('View directions'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = RetailerLinkService();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby grocery stores',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Choose a store, then check its website for the ingredients.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FlutterMap(
                  // FlutterMap keeps its camera after the first build. A
                  // location-based key recreates it whenever the user
                  // switches between device location and a ZIP code.
                  key: ValueKey(
                    '${center.latitude.toStringAsFixed(6)}:${center.longitude.toStringAsFixed(6)}',
                  ),
                  options: MapOptions(initialCenter: center, initialZoom: 12.5),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.budgetbite.budgetbite_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        for (final store in stores)
                          Marker(
                            point: store.location,
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.location_pin,
                              color: store.id == selectedId
                                  ? AppColors.green
                                  : AppColors.orange,
                              size: 42,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < stores.length; index++)
              _StoreOption(
                store: stores[index],
                index: index,
                selected: stores[index].id == selectedId,
                ingredient: searchIngredient,
                links: links,
                onSelect: () => _selectStore(context, ref, stores[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreOption extends StatelessWidget {
  const _StoreOption({
    required this.store,
    required this.index,
    required this.selected,
    required this.ingredient,
    required this.links,
    required this.onSelect,
  });

  final GroceryStore store;
  final int index;
  final bool selected;
  final String? ingredient;
  final RetailerLinkService links;
  final VoidCallback onSelect;

  Future<void> _openRetailer(BuildContext context) async {
    final uri = ingredient == null
        ? store.website
        : links.productSearch(store, ingredient!);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${store.name} does not list a website or online inventory.',
            ),
          ),
        );
      }
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This retailer link could not be opened.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = links.availabilityNote(store);
    final canOpen = ingredient != null
        ? links.productSearch(store, ingredient!) != null
        : store.website != null;
    return Card(
      color: selected ? AppColors.mint : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: onSelect,
              leading: CircleAvatar(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.ink,
                child: Text('${index + 1}'),
              ),
              title: Text(
                store.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${store.distanceMiles.toStringAsFixed(1)} mi · ${store.address}',
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: AppColors.green)
                  : null,
            ),
            if (canOpen)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openRetailer(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    links.actionLabel(store, ingredient ?? 'products'),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(
                    links.actionLabel(store, ingredient ?? 'products'),
                  ),
                ),
              ),
            if (note != null) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        size: 15,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
