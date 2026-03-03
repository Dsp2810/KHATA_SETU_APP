import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';


/// A summary card showing key metrics from the backend /summary endpoint.
class NoteSummaryCard extends StatelessWidget {
  final NoteSummary summary;
  final VoidCallback? onTap;

  const NoteSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Summary',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              if (summary.total > 0)
                Text(
                  '${summary.completionRate.toStringAsFixed(0)}% done',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MetricTile(
                icon: Icons.receipt_long_rounded,
                label: 'Total',
                value: '${summary.total}',
                color: AppColors.primary,
              ),
              _MetricTile(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: '${summary.pending}',
                color: AppColors.warning,
              ),
              _MetricTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Done',
                value: '${summary.completed}',
                color: AppColors.success,
              ),
              _MetricTile(
                icon: Icons.priority_high_rounded,
                label: 'High',
                value: '${summary.highPriority}',
                color: AppColors.credit,
              ),
            ],
          ),
          if (summary.totalAmount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Divider(color: context.dividerColor, height: 1),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.textSecondaryColor)),
                Text(
                  '${AppConstants.currencySymbol}${summary.totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.credit,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (summary.todayPending > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${summary.todayPending} pending today',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                color: context.textTertiaryColor,
              )),
        ],
      ),
    );
  }
}
