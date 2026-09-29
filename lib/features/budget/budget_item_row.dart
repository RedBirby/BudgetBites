import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/budget_item.dart';
import '../../state/app_controller.dart';

class BudgetItemRow extends ConsumerWidget {
  const BudgetItemRow({required this.item, super.key});

  final BudgetItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final itemField = TextFormField(
          initialValue: item.name,
          decoration: const InputDecoration(isDense: true, labelText: 'Item'),
          onChanged: (value) =>
              controller.updateBudgetItem(item.copyWith(name: value)),
        );
        final priceField = TextFormField(
          initialValue: item.price?.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Store price',
            prefixText: '\$ ',
          ),
          onChanged: (value) => controller.updateBudgetItem(
            item.copyWith(price: double.tryParse(value)),
          ),
        );
        final removeButton = IconButton(
          tooltip: 'Remove item',
          onPressed: () => controller.removeBudgetItem(item.id),
          icon: const Icon(Icons.close, color: AppColors.danger),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: item.checked,
                          onChanged: (value) => controller.updateBudgetItem(
                            item.copyWith(checked: value),
                          ),
                        ),
                        Expanded(child: itemField),
                        removeButton,
                      ],
                    ),
                    const SizedBox(height: 8),
                    priceField,
                  ],
                )
              : Row(
                  children: [
                    Checkbox(
                      value: item.checked,
                      onChanged: (value) => controller.updateBudgetItem(
                        item.copyWith(checked: value),
                      ),
                    ),
                    Expanded(flex: 3, child: itemField),
                    const SizedBox(width: 8),
                    SizedBox(width: 125, child: priceField),
                    removeButton,
                  ],
                ),
        );
      },
    );
  }
}
