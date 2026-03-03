import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';

/// Horizontal chip list of frequently-used product names.
/// Tapping a chip auto-fills a new item row.
class FrequentProductsChips extends StatelessWidget {
  final List<String> products;
  final ValueChanged<String> onTap;

  const FrequentProductsChips({
    super.key,
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.frequentItems,
          style: AppTextStyles.labelMedium.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final name = products[index];
              return GestureDetector(
                onTap: () => onTap(name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14,
                          color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
