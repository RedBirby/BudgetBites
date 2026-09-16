import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/dietary_preferences.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  void _toggleDiet(
    WidgetRef ref,
    DietaryPreferences preferences,
    String value,
  ) {
    final next = {...preferences.diets};
    if (next.contains(value)) {
      next.remove(value);
    } else {
      if (DietaryPreferences.primaryDiets.contains(value)) {
        next.removeAll(DietaryPreferences.primaryDiets);
      }
      next.add(value);
    }
    ref
        .read(appControllerProvider.notifier)
        .updatePreferences(preferences.copyWith(diets: next));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(
      appControllerProvider.select((state) => state.preferences),
    );
    final count = ref.watch(visibleRecipesProvider).length;
    final hasPersonalization = !preferences.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Dietary preferences')),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              eyebrow: 'Personalization',
              title: 'Make every recommendation fit',
              subtitle:
                  'Changes apply instantly to featured and live-search recipes. Always verify product labels for severe allergies.',
            ),
            const SizedBox(height: 22),
            _PreferenceSection(
              title: 'Diet style',
              subtitle:
                  'Choose one primary style. Gluten-free, Halal, and Kosher can be combined.',
              options: DietaryPreferences.dietOptions,
              selected: preferences.diets,
              onToggle: (value) => _toggleDiet(ref, preferences, value),
            ),
            const SizedBox(height: 16),
            _PreferenceSection(
              title: 'Allergies and exclusions',
              subtitle: 'Recipes containing a selected allergen are removed.',
              options: DietaryPreferences.allergyOptions,
              selected: preferences.allergies,
              onToggle: (value) {
                final next = {...preferences.allergies};
                next.contains(value) ? next.remove(value) : next.add(value);
                ref
                    .read(appControllerProvider.notifier)
                    .updatePreferences(preferences.copyWith(allergies: next));
              },
            ),
            const SizedBox(height: 16),
            _PreferenceSection(
              title: 'Nutrition goals',
              subtitle: 'Goals rank the best matches first.',
              options: DietaryPreferences.goalOptions,
              selected: preferences.goals,
              onToggle: (value) {
                final next = {...preferences.goals};
                next.contains(value) ? next.remove(value) : next.add(value);
                ref
                    .read(appControllerProvider.notifier)
                    .updatePreferences(preferences.copyWith(goals: next));
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Exact matches only',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Hide recipes that require substitutions or miss a selected nutrition goal.',
                ),
                value: preferences.exactMatches,
                onChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .updatePreferences(
                      preferences.copyWith(exactMatches: value),
                    ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final message = hasPersonalization
                      ? '$count recipe${count == 1 ? '' : 's'} fit your selected preferences.'
                      : 'Choose a diet, allergy, or nutrition goal to personalize your recipes.';
                  final action = FilledButton(
                    onPressed: () => context.go('/discover'),
                    child: const Text('View recipes'),
                  );
                  final messageRow = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                  return constraints.maxWidth < 600
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            messageRow,
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: action,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: messageRow),
                            const SizedBox(width: 14),
                            action,
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
  });
  final String title;
  final String subtitle;
  final Set<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  selected: selected.contains(option),
                  label: Text(option),
                  onSelected: (_) => onToggle(option),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
