import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 760;
    final showUsername = screenWidth >= 430;
    final tinyHeader = screenWidth < 360;
    final username = state.session?.username ?? 'Guest';
    final locationLabel =
        state.zipCode ??
        (state.userLocation == null ? 'Set location' : 'Near me');
    return Scaffold(
      appBar: AppBar(
        titleSpacing: screenWidth < 430 ? 8 : null,
        title: Tooltip(
          message: 'Go to home',
          child: InkWell(
            onTap: () {
              ref.read(appControllerProvider.notifier).clearRecipeSearch();
              context.go('/discover');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: _BudgetBiteLogo(tiny: tinyHeader),
            ),
          ),
        ),
        actions: [
          if (compact)
            IconButton(
              tooltip: 'Set shopping location',
              onPressed: () => context.push('/location'),
              icon: const Icon(Icons.location_on_outlined),
            )
          else
            TextButton.icon(
              onPressed: () => context.push('/location'),
              icon: const Icon(Icons.location_on_outlined),
              label: Text(locationLabel),
            ),
          if (compact)
            IconButton(
              tooltip: 'Dietary preferences',
              onPressed: () => context.push('/preferences'),
              icon: const Icon(Icons.tune_rounded),
            )
          else
            TextButton.icon(
              onPressed: () => context.push('/preferences'),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Preferences'),
            ),
          if (!showUsername)
            IconButton(
              tooltip: 'Account center: $username',
              onPressed: () => context.push('/account'),
              icon: CircleAvatar(
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.green,
                child: Text(username.substring(0, 1).toUpperCase()),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => context.push('/account'),
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.green,
                child: Text(username.substring(0, 1).toUpperCase()),
              ),
              label: Text(username),
            ),
          SizedBox(width: compact ? 2 : 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket),
            label: 'My plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

class _BudgetBiteLogo extends StatelessWidget {
  const _BudgetBiteLogo({required this.tiny});

  final bool tiny;

  @override
  Widget build(BuildContext context) => tiny
      ? const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.green,
          child: Icon(Icons.eco_rounded, color: Colors.white),
        )
      : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.green,
              child: Icon(Icons.eco_rounded, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('BudgetBite', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        );
}
