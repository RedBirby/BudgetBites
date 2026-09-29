import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/grocery_store.dart';
import '../../services/retailer_link_service.dart';
import '../../state/app_controller.dart';
import 'plan_links.dart';
import 'store_option.dart';

class StoresCard extends ConsumerWidget {
  const StoresCard({
    required this.stores,
    required this.center,
    required this.selectedId,
    required this.searchIngredient,
    super.key,
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
              await launchExternalLink(
                dialogContext,
                directionsUri(
                  store.location.latitude,
                  store.location.longitude,
                ),
                failureMessage: 'Directions could not be opened.',
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
              height: MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 220
                  : 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: FlutterMap(
                  key: ValueKey(
                    '${center.latitude.toStringAsFixed(6)}:${center.longitude.toStringAsFixed(6)}',
                  ),
                  options: MapOptions(initialCenter: center, initialZoom: 12.5),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.robert.budgetbites',
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
              StoreOption(
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
