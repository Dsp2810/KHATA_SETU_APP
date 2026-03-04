import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/customer_model.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/data/models/daily_summary_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/premium_animations.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

/// Customer transaction timeline — shows all transactions grouped by date
/// with sticky daily summary headers, animated balance changes, and quick-add.
class CustomerTimelinePage extends StatefulWidget {
  final String customerId;

  const CustomerTimelinePage({super.key, required this.customerId});

  @override
  State<CustomerTimelinePage> createState() => _CustomerTimelinePageState();
}

class _CustomerTimelinePageState extends State<CustomerTimelinePage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    // Load transactions once in initState, not in build()
    context.read<TransactionBloc>().add(LoadTransactions(widget.customerId));
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionAdded) {
              HapticFeedback.mediumImpact();
              final txn = state.transaction;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(txn.isCredit
                    ? context.l10n.creditOfAmountAdded(txn.totalAmount.toStringAsFixed(0))
                    : context.l10n.paymentOfAmountRecorded(txn.totalAmount.toStringAsFixed(0))),
                backgroundColor:
                    txn.isCredit ? AppColors.error : AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            } else if (state is TransactionUndone) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    context.l10n.transactionUndoneAmount(state.undoneTransaction.totalAmount.toStringAsFixed(0))),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            } else if (state is TransactionError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          buildWhen: (prev, curr) =>
              curr is TransactionLoaded ||
              curr is TransactionLoading ||
              curr is TransactionInitial,
          builder: (context, state) {
            if (state is TransactionLoaded) {
              return _buildContent(context, state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: _buildQuickAddFab(context),
    );
  }

  Widget _buildContent(BuildContext context, TransactionLoaded state) {
    final customer = state.customer;
    final grouped = state.groupedByDate;
    final sortedDateKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(context, customer),
          _buildBalanceSummary(context, state),
          Expanded(
            child: sortedDateKeys.isEmpty
                ? PremiumEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: context.l10n.noTransactions,
                    subtitle: context.l10n.tapToAddFirstCreditOrPayment,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.navClearance),
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedDateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDateKeys[index];
                      final txns = grouped[dateKey]!;
                      final summary = state.dailySummaries
                          .where((s) => s.dateKey == dateKey)
                          .firstOrNull;
                      return _DateGroup(
                        dateKey: dateKey,
                        transactions: txns,
                        summary: summary,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CustomerModel? customer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_rounded,
                color: context.textPrimaryColor),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?.name ?? context.l10n.customer,
                  style: AppTextStyles.h3
                      .copyWith(color: context.textPrimaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (customer != null)
                  Text(
                    customer.phone,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textSecondaryColor),
                  ),
              ],
            ),
          ),
          // Undo button
          SpringContainer(
            onTap: () {
              context
                  .read<TransactionBloc>()
                  .add(UndoLastTransaction(widget.customerId));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.glassColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.glassBorderColor),
              ),
              child: Icon(Icons.undo_rounded,
                  size: 20, color: context.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary(
      BuildContext context, TransactionLoaded state) {
    final balance = state.netBalance;
    final isOwing = balance > 0;
    final customer = state.customer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _headerAnimController,
                curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _headerAnimController,
          child: GlassCard(
            child: Column(
              children: [
                // Main balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOwing
                          ? Icons.arrow_upward_rounded
                          : Icons.check_circle_rounded,
                      color: isOwing ? AppColors.error : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    CountingText(
                      value: balance.abs(),
                      prefix: '₹',
                      style: AppTextStyles.h1.copyWith(
                        color: isOwing ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  isOwing ? context.l10n.outstandingBalance : context.l10n.allSettled,
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Credit limit warning
                if (customer != null && customer.isOverCreditLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded,
                            color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.overCreditLimitAmount(customer.creditLimit.toStringAsFixed(0)),
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // Overdue warning
                if (customer != null && customer.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.overdueWithDays(customer.daysSinceLastTransaction ?? 0),
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),
                Divider(
                    color: context.glassBorderColor, height: 1),
                const SizedBox(height: AppSpacing.sm),

                // Summary row
                Row(
                  children: [
                    _SummaryChip(
                      label: context.l10n.creditLabel,
                      amount: state.totalCredit,
                      color: AppColors.error,
                      icon: Icons.arrow_upward_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: context.glassBorderColor),
                    _SummaryChip(
                      label: context.l10n.paymentsLabel,
                      amount: state.totalPayment,
                      color: AppColors.success,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: context.glassBorderColor),
                    _SummaryChip(
                      label: context.l10n.entriesLabel,
                      amount: state.transactionCount.toDouble(),
                      color: AppColors.primary,
                      icon: Icons.receipt_long_rounded,
                      isCount: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Credit button
        Container(
          decoration: BoxDecoration(
            gradient: AppGradients.dangerGradient,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            boxShadow: [
              BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: FloatingActionButton.small(
            heroTag: 'credit',
            onPressed: () =>
                _showQuickAddSheet(context, isCredit: true),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.arrow_upward_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Payment button
        Container(
          decoration: BoxDecoration(
            gradient: AppGradients.successGradient,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: FloatingActionButton.small(
            heroTag: 'payment',
            onPressed: () =>
                _showQuickAddSheet(context, isCredit: false),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.arrow_downward_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  void _showQuickAddSheet(BuildContext context,
      {required bool isCredit}) {
    _amountController.clear();
    _descController.clear();
    int paymentMode = 0;

    final bloc = context.read<TransactionBloc>();

    showGlassBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GradientText(
                      text: isCredit ? context.l10n.addCredit : context.l10n.recordPayment,
                      style: AppTextStyles.h3,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded,
                          color: context.textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: AppTextStyles.h2
                      .copyWith(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.l10n.amount,
                    labelStyle: TextStyle(
                        color: context.textSecondaryColor),
                    prefixText: '₹ ',
                    prefixStyle: AppTextStyles.h2
                        .copyWith(color: context.textPrimaryColor),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextField(
                  controller: _descController,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: context.l10n.descriptionOptional,
                    labelStyle: TextStyle(
                        color: context.textSecondaryColor),
                    hintText: isCredit
                        ? context.l10n.groceryPurchaseHint
                        : context.l10n.cashPaymentHint,
                    hintStyle: TextStyle(
                        color: context.textSecondaryColor),
                    prefixIcon: Icon(Icons.note_outlined,
                        color: context.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Payment mode (for payments)
                if (!isCredit) ...[
                  Text(context.l10n.paymentMode,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: context.textPrimaryColor)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _PaymentModeChip(
                        label: '💵 ${context.l10n.cash}',
                        isSelected: paymentMode == 0,
                        onTap: () =>
                            setModalState(() => paymentMode = 0),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PaymentModeChip(
                        label: '📱 ${context.l10n.upi}',
                        isSelected: paymentMode == 1,
                        onTap: () =>
                            setModalState(() => paymentMode = 1),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PaymentModeChip(
                        label: '💳 ${context.l10n.bank}',
                        isSelected: paymentMode == 2,
                        onTap: () =>
                            setModalState(() => paymentMode = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Submit button
                MorphingGradientButton(
                  label: isCredit
                      ? context.l10n.addCreditEntry
                      : context.l10n.recordPayment,
                  icon: isCredit
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  gradient: isCredit
                      ? AppGradients.dangerGradient
                      : AppGradients.successGradient,
                  width: double.infinity,
                  onTap: _amountController.text.isEmpty
                      ? null
                      : () {
                          final amount = double.tryParse(
                              _amountController.text.trim());
                          if (amount == null || amount <= 0) return;

                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();

                          if (isCredit) {
                            bloc.add(AddCredit(
                              customerId: widget.customerId,
                              amount: amount,
                              description:
                                  _descController.text.trim().isEmpty
                                      ? null
                                      : _descController.text.trim(),
                            ));
                          } else {
                            bloc.add(AddPayment(
                              customerId: widget.customerId,
                              amount: amount,
                              paymentMode: paymentMode,
                              description:
                                  _descController.text.trim().isEmpty
                                      ? null
                                      : _descController.text.trim(),
                            ));
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ Sub-Widgets ═══════════════════════

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isCount;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            isCount
                ? amount.toInt().toString()
                : '₹${amount.toStringAsFixed(0)}',
            style: AppTextStyles.labelLarge
                .copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: context.textSecondaryColor, fontSize: 10)),
        ],
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<TransactionModel> transactions;
  final DailySummaryModel? summary;
  final int index;

  const _DateGroup({
    required this.dateKey,
    required this.transactions,
    this.summary,
    required this.index,
  });

  String _formatDateKey(String dateKey, BuildContext context) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return context.l10n.today;
    if (dateKey == yesterday) return context.l10n.yesterday;

    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedListItem(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with summary
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  _formatDateKey(dateKey, context),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (summary != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.glassColor,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: context.glassBorderColor),
                    ),
                    child: Text(
                      'Net: ${summary!.netAmount >= 0 ? '+' : ''}₹${summary!.netAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(
                        color: summary!.netAmount >= 0
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Container(
                      height: 1,
                      margin:
                          const EdgeInsets.only(left: AppSpacing.sm),
                      color: context.glassBorderColor,
                    ),
                  ),
              ],
            ),
          ),

          // Transaction cards
          ...transactions.asMap().entries.map((entry) =>
              AnimatedListItem(
                index: entry.key,
                delay: Duration(milliseconds: 50 * entry.key),
                child:
                    _TransactionCard(transaction: entry.value),
              )),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionCard({required this.transaction});

  IconData _paymentModeIcon(int mode) {
    switch (mode) {
      case 1:
        return Icons.phone_android_rounded;
      case 2:
        return Icons.credit_card_rounded;
      case 3:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.money_rounded;
    }
  }

  String _paymentModeLabel(int mode, BuildContext context) {
    switch (mode) {
      case 1:
        return 'UPI';
      case 2:
        return context.l10n.bank.toUpperCase();
      case 3:
        return context.l10n.otherPayment.toUpperCase();
      default:
        return context.l10n.cash.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Type icon
            GradientIconBox(
              icon: isCredit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              gradient: isCredit
                  ? AppGradients.dangerGradient
                  : AppGradients.successGradient,
              size: 40,
              iconSize: 20,
              borderRadius: 12,
            ),
            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCredit ? context.l10n.creditUdhar : context.l10n.payment,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty)
                    Text(
                      transaction.description!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.textSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Items count + payment mode + time
                  Row(
                    children: [
                      if (transaction.items.isNotEmpty) ...[
                        Icon(Icons.shopping_bag_outlined,
                            size: 11,
                            color: context.textSecondaryColor),
                        const SizedBox(width: 2),
                        Text(
                          '${transaction.items.length} items',
                          style: AppTextStyles.caption.copyWith(
                              color: context.textSecondaryColor,
                              fontSize: 10),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Icon(
                          _paymentModeIcon(
                              transaction.paymentMode),
                          size: 11,
                          color: context.textSecondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        _paymentModeLabel(
                            transaction.paymentMode, context),
                        style: AppTextStyles.caption.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 10),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormat('hh:mm a')
                            .format(transaction.timestamp),
                        style: AppTextStyles.caption.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount + balance after
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₹${transaction.totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.h4.copyWith(
                      color: color, fontWeight: FontWeight.w800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.glassColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: context.glassBorderColor),
                  ),
                  child: Text(
                    'Bal: ₹${transaction.balanceAfter.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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

class _PaymentModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          gradient:
              isSelected ? AppGradients.primaryGradient : null,
          color: isSelected ? null : context.glassColor,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : context.glassBorderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : context.textSecondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
