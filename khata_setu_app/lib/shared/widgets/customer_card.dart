import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';

class CustomerCard extends StatelessWidget {
  final String name;
  final String phone;
  final double balance;
  final String? avatarUrl;
  final int? riskScore;
  final DateTime? lastTransaction;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  const CustomerCard({
    super.key,
    required this.name,
    required this.phone,
    required this.balance,
    this.avatarUrl,
    this.riskScore,
    this.lastTransaction,
    this.onTap,
    this.onCall,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDebt = balance > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: _getStatusColor(),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: context.isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (riskScore != null) _buildRiskBadge(context),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  if (lastTransaction != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatLastTransaction(context),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Balance and Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppConstants.currencySymbol}${balance.abs().toStringAsFixed(0)}',
                  style: AppTextStyles.h4.copyWith(
                    color: isDebt ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isDebt ? context.l10n.toCollect : context.l10n.advance,
                  style: AppTextStyles.caption.copyWith(
                    color: isDebt ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onCall != null)
                      _buildActionButton(
                        Icons.call_outlined,
                        AppColors.success,
                        onCall!,
                      ),
                    if (onMessage != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _buildActionButton(
                        Icons.message_outlined,
                        AppColors.primary,
                        onMessage!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(BuildContext context) {
    Color color;
    String label;

    if (riskScore! >= 80) {
      color = AppColors.success;
      label = context.l10n.lowRisk;
    } else if (riskScore! >= 50) {
      color = AppColors.warning;
      label = context.l10n.mediumRisk;
    } else {
      color = AppColors.error;
      label = context.l10n.highRisk;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Color _getStatusColor() {
    if (balance <= 0) return AppColors.success;
    if (balance < 1000) return AppColors.warning;
    return AppColors.error;
  }

  String _formatLastTransaction(BuildContext context) {
    if (lastTransaction == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastTransaction!);

    if (diff.inDays == 0) return context.l10n.today;
    if (diff.inDays == 1) return context.l10n.yesterday;
    if (diff.inDays < 7) return context.l10n.daysAgoLong(diff.inDays);
    if (diff.inDays < 30) return context.l10n.weeksAgoLong((diff.inDays / 7).floor());
    return context.l10n.monthsAgoLong((diff.inDays / 30).floor());
  }
}
