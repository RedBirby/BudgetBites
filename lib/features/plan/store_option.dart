import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/grocery_store.dart';
import '../../services/retailer_link_service.dart';
import 'plan_links.dart';

class StoreOption extends StatelessWidget {
  const StoreOption({
    required this.store,
    required this.index,
    required this.selected,
    required this.ingredient,
    required this.links,
    required this.onSelect,
    super.key,
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
    await launchExternalLink(
      context,
      uri,
      failureMessage: 'This retailer link could not be opened.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = links.availabilityNote(store);
    final canOpen = ingredient != null
        ? links.productSearch(store, ingredient!) != null
        : links.isUsableWebUri(store.website);
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canOpen ? () => _openRetailer(context) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canOpen ? Icons.open_in_new : Icons.language,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        links.actionLabel(store, ingredient ?? 'products'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
