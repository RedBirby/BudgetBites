import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LocationConfirmation extends StatelessWidget {
  const LocationConfirmation({
    required this.zipCode,
    required this.storeCount,
    super.key,
  });

  final String? zipCode;
  final int storeCount;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.mint,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, color: AppColors.green, size: 31),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.greenDark,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location received',
                  style: TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  zipCode == null
                      ? 'Showing stores near your approximate current location.'
                      : 'Showing stores near ZIP $zipCode.',
                  style: const TextStyle(color: AppColors.ink, height: 1.35),
                ),
                const SizedBox(height: 3),
                Text(
                  '$storeCount nearby ${storeCount == 1 ? 'store' : 'stores'} found',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: AppColors.green, size: 24),
        ],
      ),
    ),
  );
}
