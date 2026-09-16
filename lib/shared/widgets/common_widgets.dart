import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 620;
      final titleStyle = Theme.of(context).textTheme.displaySmall;
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: narrow ? titleStyle?.copyWith(fontSize: 32) : titleStyle,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      );
      if (trailing == null) return heading;
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: trailing),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: heading),
          trailing!,
        ],
      );
    },
  );
}

class PreferenceChip extends StatelessWidget {
  const PreferenceChip(
    this.label, {
    this.icon = Icons.check_rounded,
    this.tone = AppColors.mint,
    super.key,
  });
  final String label;
  final IconData icon;
  final Color tone;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 15, color: AppColors.green),
    label: Text(label),
    backgroundColor: tone,
    side: BorderSide.none,
    labelStyle: const TextStyle(
      color: AppColors.green,
      fontWeight: FontWeight.w700,
    ),
  );
}

class HelpfulHint extends StatelessWidget {
  const HelpfulHint({
    required this.text,
    this.icon = Icons.lightbulb_outline,
    super.key,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
