import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/animations.dart';
import '../../core/utils/app_formatter.dart';

/// Model for a bill item
class BillItemData {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? unit;
  final String? category;

  const BillItemData({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.unit,
    this.category,
  });

  double get total => quantity * price;
}

/// Model for bill data
class BillData {
  final String? billId;
  final String customerName;
  final String? customerPhone;
  final List<BillItemData> items;
  final DateTime date;
  final double? discount;
  final String? paymentMode;
  final bool isPaid;
  final String? notes;

  const BillData({
    this.billId,
    required this.customerName,
    this.customerPhone,
    required this.items,
    required this.date,
    this.discount,
    this.paymentMode,
    this.isPaid = false,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => discount ?? 0;
  double get grandTotal => subtotal - discountAmount;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Generate natural language summary like "Dhaval has taken 3 packets, 2 chocolates"
  String get naturalSummary {
    if (items.isEmpty) return '';

    final itemDescriptions = items.map((item) {
      return '${item.quantity} ${item.name.toLowerCase()}';
    }).toList();

    if (itemDescriptions.length == 1) {
      return '$customerName has taken ${itemDescriptions.first}';
    }

    final lastItem = itemDescriptions.removeLast();
    return '$customerName has taken ${itemDescriptions.join(', ')} and $lastItem';
  }
}

/// Compact bill summary card for lists
class BillSummaryCard extends StatelessWidget {
  final BillData bill;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;
  final int index;

  const BillSummaryCard({
    super.key,
    required this.bill,
    this.onTap,
    this.onShare,
    this.onPrint,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedListItem(
      index: index,
      child: AnimatedScaleOnTap(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xs),
              _buildSummaryText(context),
              const SizedBox(height: AppSpacing.sm),
              _buildItemsList(context),
              const Divider(height: AppSpacing.lg),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bill.isPaid
                  ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                  : [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            bill.isPaid ? Icons.check_circle : Icons.pending,
            color: AppColors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.customerName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                _formatDate(bill.date, context),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        if (bill.billId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${bill.billId}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryText(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: context.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              bill.naturalSummary,
              style: AppTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    // Show max 3 items, with "and X more" if needed
    final displayItems = bill.items.take(3).toList();
    final remainingCount = bill.items.length - 3;

    return Column(
      children: [
        ...displayItems.asMap().entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.grey200.withValues(alpha: context.isDark ? 0.2 : 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                Text(
                  '₹${item.total.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.moreItemsCount(remainingCount),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.totalItemsLabel(bill.totalItems),
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${bill.grandTotal.toStringAsFixed(0)}',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (onShare != null)
          IconButton(
            onPressed: onShare,
            icon: Icon(
              Icons.share_outlined,
              color: context.textSecondaryColor,
            ),
            tooltip: context.l10n.share,
          ),
        if (onPrint != null)
          IconButton(
            onPressed: onPrint,
            icon: Icon(
              Icons.print_outlined,
              color: context.textSecondaryColor,
            ),
            tooltip: context.l10n.print,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bill.isPaid
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            bill.isPaid ? context.l10n.paidStatus : context.l10n.pendingStatus,
            style: AppTextStyles.labelSmall.copyWith(
              color: bill.isPaid ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billDate = DateTime(date.year, date.month, date.day);

    if (billDate == today) {
      return context.l10n.todayWithTime(_formatTime(date));
    } else if (billDate == today.subtract(const Duration(days: 1))) {
      return context.l10n.yesterdayWithTime(_formatTime(date));
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}

/// Detailed bill view for modal or full page
class BillDetailView extends StatelessWidget {
  final BillData bill;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkPaid;

  const BillDetailView({
    super.key,
    required this.bill,
    this.onPrint,
    this.onShare,
    this.onEdit,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNaturalSummary(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildItemsTable(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTotals(context),
                  if (bill.notes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildNotes(context),
                  ],
                ],
              ),
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.grey400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bill.customerName,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bill.isPaid
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bill.isPaid ? context.l10n.paidStatus : context.l10n.pendingStatus,
                        style: AppTextStyles.caption.copyWith(
                          color: bill.isPaid ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatFullDate(bill.date)} • ${context.l10n.itemsCount(bill.totalItems)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                if (bill.billId != null)
                  Text(
                    context.l10n.billIdLabel(bill.billId!),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNaturalSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: context.isDark ? 0.2 : 0.1),
            AppColors.secondary.withValues(alpha: context.isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.billSummary,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            bill.naturalSummary,
            style: AppTextStyles.bodyLarge.copyWith(
              fontStyle: FontStyle.italic,
              color: context.textPrimaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.itemsHeader,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.dividerColor,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _buildTableHeader(context),
              ...bill.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildTableRow(item, index, context);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.l10n.pdfItemName,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              context.l10n.pdfQty,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              context.l10n.rate,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              context.l10n.amount,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BillItemData item, int index, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                  ),
                ),
                if (item.category != null)
                  Text(
                    item.category!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '₹${item.price.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '₹${item.total.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.grey800.withValues(alpha: 0.5) : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _buildTotalRow(context.l10n.subtotal, '₹${bill.subtotal.toStringAsFixed(0)}', context),
          if (bill.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              context.l10n.discount,
              '-₹${bill.discountAmount.toStringAsFixed(0)}',
              context,
              valueColor: AppColors.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildTotalRow(
            context.l10n.grandTotal,
            '₹${bill.grandTotal.toStringAsFixed(0)}',
            context,
            isBold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value,
    BuildContext context, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium).copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.h4 : AppTextStyles.bodyMedium).copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note_outlined,
            size: 18,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.notesSection,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bill.notes!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onPrint != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print),
                label: Text(context.l10n.print),
              ),
            ),
          if (onPrint != null && onShare != null)
            const SizedBox(width: AppSpacing.sm),
          if (onShare != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                label: Text(context.l10n.share),
              ),
            ),
          if ((onPrint != null || onShare != null) && !bill.isPaid && onMarkPaid != null)
            const SizedBox(width: AppSpacing.sm),
          if (!bill.isPaid && onMarkPaid != null)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onMarkPaid,
                icon: const Icon(Icons.check_circle),
                label: Text(context.l10n.markAsPaid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}

/// Mini bill preview for quick glance
class BillMiniPreview extends StatelessWidget {
  final BillData bill;
  final VoidCallback? onTap;

  const BillMiniPreview({
    super.key,
    required this.bill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    bill.customerName[0].toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bill.customerName,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.itemsCount(bill.totalItems),
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${bill.grandTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bill.isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
