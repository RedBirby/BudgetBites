import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';
import '../plan/location_gate.dart';
import 'budget_item_row.dart';
import 'total_line.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    if (state.stores.isEmpty) return const PageContainer(child: LocationGate());
    final money = NumberFormat.simpleCurrency();
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'Grocery checkbook',
            title: 'Budget book',
            subtitle:
                'Build a pre-receipt using the store selected in My Plan and understand the total before checkout.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 850;
              final receipt = Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.mint,
                            foregroundColor: AppColors.green,
                            child: Icon(Icons.receipt_long),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PRE-RECEIPT',
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  state.selectedStore?.name ??
                                      'Choose a store in My Plan',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  state.selectedStore?.address ?? '',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      if (state.budgetItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 34),
                          child: Center(
                            child: Text(
                              'Your pre-receipt is empty. Add an item or import your planned ingredients.',
                            ),
                          ),
                        )
                      else
                        for (final item in state.budgetItems)
                          BudgetItemRow(item: item),
                      const Divider(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.addBudgetItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add item'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.plannedRecipes.isEmpty
                                ? null
                                : controller.importPlanToBudget,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(
                              state.plannedRecipes.length > 1
                                  ? 'Import ${state.plannedRecipes.length} planned recipes'
                                  : 'Import planned ingredients',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      TotalLine(
                        label: 'Grocery subtotal',
                        value: money.format(state.subtotal),
                      ),
                      TotalLine(
                        label:
                            'Estimated local tax (${state.taxRate.toStringAsFixed(2)}%)',
                        value: money.format(state.tax),
                      ),
                      const Divider(),
                      TotalLine(
                        label: 'Estimated checkout total',
                        value: money.format(state.checkoutTotal),
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              );
              final summary = Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.mint,
                        foregroundColor: AppColors.green,
                        child: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Stay on track',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Set the amount you want to spend this week.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        initialValue: state.weeklyBudget.toStringAsFixed(0),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weekly grocery budget',
                          prefixText: '\$ ',
                        ),
                        onChanged: (value) => controller.setWeeklyBudget(
                          double.tryParse(value) ?? 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey('${state.taxRate}-${state.taxIsManual}'),
                        initialValue: state.taxRate.toStringAsFixed(2),
                        readOnly: !state.taxIsManual,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Store-area tax',
                          suffixText: '%',
                          helperText: state.selectedStore?.zipCode == null
                              ? 'Based on the selected store address when available.'
                              : 'Store ZIP ${state.selectedStore!.zipCode}',
                        ),
                        onChanged: (value) => controller.setManualTax(
                          double.tryParse(value) ?? 0,
                        ),
                      ),
                      if (state.loadingTax) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 6),
                        const Text(
                          'Updating the estimate for this store…',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (state.taxError != null && !state.loadingTax) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.taxError!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (state.taxIsManual)
                        OutlinedButton.icon(
                          onPressed: controller.restoreAutomaticTax,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Restore automatic store estimate'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () =>
                              controller.setManualTax(state.taxRate),
                          icon: const Icon(Icons.edit),
                          label: const Text('Tax looks wrong? Change it'),
                        ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: state.weeklyBudget <= 0
                            ? 0
                            : (state.checkoutTotal / state.weeklyBudget)
                                  .clamp(0, 1)
                                  .toDouble(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${money.format(state.weeklyBudget - state.checkoutTotal)} remaining',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: state.checkoutTotal > state.weeklyBudget
                              ? AppColors.danger
                              : AppColors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tax is an estimate. Grocery exemptions, prepared food, and non-food products can change the final receipt.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: receipt),
                        const SizedBox(width: 18),
                        Expanded(child: summary),
                      ],
                    )
                  : Column(
                      children: [receipt, const SizedBox(height: 18), summary],
                    );
            },
          ),
        ],
      ),
    );
  }
}
