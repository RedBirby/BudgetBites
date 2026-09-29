import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'hero_image.dart';

const heroImageUrl =
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=85';

class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key});

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
          const hero = HeroImage(
            imageUrl: heroImageUrl,
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
                      const SizedBox(width: 330, child: hero),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
