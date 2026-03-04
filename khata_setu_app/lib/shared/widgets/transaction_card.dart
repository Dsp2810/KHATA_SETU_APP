import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_formatter.dart';
import '../../core/utils/ledger_rules.dart';

// Re-export TransactionType for backward compatibility
export '../../core/utils/ledger_rules.dart' show TransactionType;

enum PaymentMode { cash, upi, bank, other }

class TransactionCard extends StatelessWidget {
  final String customerName;
  final double amount;
  final TransactionType type;
  final PaymentMode paymentMode;
  final DateTime date;
  final String? description;
  final String? productName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.paymentMode,
    required this.date,
    this.description,
    this.productName,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = type == TransactionType.credit;

    return Dismissible(
      key: UniqueKey(),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
        ),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (isCredit ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isCredit ? AppColors.error : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        _buildPaymentModeBadge(context),
                        const SizedBox(width: AppSpacing.xs),
                        if (productName != null)
                          Expanded(
                            child: Text(
                              productName!,
                              style: AppTextStyles.caption.copyWith(
                                color: context.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Amount and Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                    style: AppTextStyles.h4.copyWith(
                      color: isCredit ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatDate(context),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeBadge(BuildContext context) {
    IconData icon;
    Color color;
    String modeLabel;

    switch (paymentMode) {
      case PaymentMode.cash:
        icon = Icons.money_outlined;
        color = AppColors.success;
        modeLabel = context.l10n.cash;
        break;
      case PaymentMode.upi:
        icon = Icons.account_balance_wallet_outlined;
        color = AppColors.primary;
        modeLabel = context.l10n.upi;
        break;
      case PaymentMode.bank:
        icon = Icons.account_balance_outlined;
        color = AppColors.secondary;
        modeLabel = context.l10n.bank;
        break;
      case PaymentMode.other:
        icon = Icons.payment_outlined;
        color = AppColors.grey500;
        modeLabel = context.l10n.otherPayment;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            modeLabel.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (transactionDate == yesterday) {
      return context.l10n.yesterday;
    }

    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
