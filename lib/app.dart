import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'shared/widgets/offline_status_banner.dart';

class BudgetBiteApp extends ConsumerWidget {
  const BudgetBiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'BudgetBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) =>
          OfflineStatusBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
