import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class TotalLine extends StatelessWidget {
  const TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 22 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
