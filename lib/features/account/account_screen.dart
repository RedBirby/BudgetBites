import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/user_session.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../state/app_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final session = state.session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account center')),
        body: PageContainer(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 46,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to view your account',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your preferences, saved recipes, and budget book appear here after you sign in.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Go to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final avatar = CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      child: Text(
        session.username.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.role == UserRole.admin
              ? 'ADMINISTRATOR'
              : session.isGuest
              ? 'GUEST ACCOUNT'
              : 'BUDGETBITE MEMBER',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          session.username,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          session.isGuest
              ? 'Dietary restrictions are available. Create an account to persist saved recipes and plans.'
              : 'Your preferences, recipes, grocery plan, and budget book are stored separately on this device.',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Account center')),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 520
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            avatar,
                            const SizedBox(height: 16),
                            identity,
                          ],
                        )
                      : Row(
                          children: [
                            avatar,
                            const SizedBox(width: 16),
                            Expanded(child: identity),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.green,
                    ),
                    title: const Text(
                      'Dietary restrictions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      state.preferences.isEmpty
                          ? 'No restrictions selected'
                          : [
                              ...state.preferences.diets,
                              ...state.preferences.allergies.map(
                                (item) => '$item-free',
                              ),
                              ...state.preferences.goals,
                            ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/preferences'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.store_outlined,
                      color: AppColors.green,
                    ),
                    title: const Text(
                      'Preferred store',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      state.selectedStore?.name ?? 'Choose a store in My Plan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/plan'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline,
                      color: AppColors.green,
                    ),
                    title: const Text(
                      'Saved recipes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${state.savedRecipeIds.length} saved'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/saved'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: () {
                ref.read(appControllerProvider.notifier).signOut();
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            if (session.role == UserRole.admin) ...[
              const SizedBox(height: 12),
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.monitor_heart_outlined,
                    color: AppColors.green,
                  ),
                  title: Text(
                    'Diagnostics',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Admin-only runtime diagnostics are ready for connection to your logging backend.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
