import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return Row(
          children: [
            if (wide)
              Expanded(
                flex: 11,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.greenDark, AppColors.green],
                    ),
                  ),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'BudgetBite',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Eat well.\nSpend thoughtfully.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(color: Colors.white, fontSize: 58),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Turn recipes into affordable grocery trips tailored to your budget, location, and dietary needs.',
                        style: TextStyle(
                          color: Color(0xFFE1ECE5),
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            Expanded(
              flex: wide ? 9 : 1,
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
