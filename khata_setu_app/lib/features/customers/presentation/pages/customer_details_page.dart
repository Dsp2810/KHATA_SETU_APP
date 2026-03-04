import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../features/ledger/presentation/bloc/transaction_bloc.dart';
import '../../../../features/ledger/presentation/bloc/transaction_event.dart';
import '../../../../features/ledger/presentation/bloc/transaction_state.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _headerAnimController.forward();

    // Load transactions for this customer
    context.read<TransactionBloc>().add(LoadTransactions(widget.customerId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, txnState) {
        // Get customer from TransactionLoaded or fall back to CustomerBloc
        CustomerModel? customer;
        List<TransactionModel> transactions = [];
        double totalCredit = 0;
        double totalPayment = 0;

        if (txnState is TransactionLoaded &&
            txnState.customerId == widget.customerId) {
          customer = txnState.customer;
          transactions = txnState.transactions;
          totalCredit = txnState.totalCredit;
          totalPayment = txnState.totalPayment;
        }

        // If customer still null, try CustomerBloc
        if (customer == null) {
          final custState = context.read<CustomerBloc>().state;
          if (custState is CustomerLoaded) {
            customer = custState.customers
                .where((c) => c.id == widget.customerId)
                .firstOrNull;
          }
        }

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(isDark, customer!, totalCredit, totalPayment),
            ],
            body: Column(
              children: [
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsTab(isDark, transactions),
                      _buildOverviewTab(
                        isDark,
                        customer,
                        totalCredit,
                        totalPayment,
                        transactions,
                      ),
                      _buildDetailsTab(isDark, customer),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    bool isDark,
    CustomerModel customer,
    double totalCredit,
    double totalPayment,
  ) {
    final trustColor = customer.trustScore >= 80
        ? AppColors.success
        : customer.trustScore >= 50
        ? AppColors.warning
        : AppColors.error;

    return SliverAppBar(
      expandedHeight: context.responsive.sliverExpandedHeight,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit, color: AppColors.white, size: 20),
          ),
          onPressed: () {
              context.push('/customers/${customer.id}/edit', extra: customer);
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert,
              color: AppColors.white,
              size: 20,
            ),
          ),
          onPressed: () => _showOptionsSheet(customer),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: FadeTransition(
                opacity: _headerFadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar with trust ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(
                            value: customer.trustScore / 100,
                            strokeWidth: 3,
                            backgroundColor: AppColors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(trustColor),
                          ),
                        ),
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.white,
                          child: Text(
                            customer.avatar ??
                                customer.name.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      customer.name,
                      style: AppTextStyles.h3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Balance card
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeaderStat(
                            context.l10n.balanceLabel,
                            '${AppConstants.currencySymbol}${customer.currentBalance.abs().toStringAsFixed(0)}',
                            customer.currentBalance > 0
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                          _buildHeaderStat(
                            context.l10n.trustLabel,
                            '${customer.trustScore}%',
                            trustColor,
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                          _buildHeaderStat(
                            context.l10n.limitLabel,
                            '${AppConstants.currencySymbol}${customer.creditLimit.toStringAsFixed(0)}',
                            AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey300),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? context.surfaceColor.withValues(alpha: 0.85)
            : context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? AppColors.grey400 : AppColors.grey500,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            icon: Icon(Icons.receipt_long, size: 20),
            text: context.l10n.transactions,
          ),
          Tab(
            icon: Icon(Icons.insights, size: 20),
            text: context.l10n.overview,
          ),
          Tab(
            icon: Icon(Icons.person, size: 20),
            text: context.l10n.detailsTab,
          ),
        ],
      ),
    );
  }

  // ---- TRANSACTIONS TAB ----
  Widget _buildTransactionsTab(
    bool isDark,
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(
              context.l10n.noTransactionsYet,
              style: AppTextStyles.h4.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        return AnimatedListItem(
          index: index,
          child: _buildTransactionTile(txn, isDark),
        );
      },
    );
  }

  Widget _buildTransactionTile(TransactionModel txn, bool isDark) {
    final isCredit = txn.isCredit;
    final color = isCredit ? AppColors.error : AppColors.success;
    final dateStr = _formatDate(txn.timestamp);
    final timeStr = DateFormat('hh:mm a').format(txn.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              Container(width: 2, height: 60, color: AppColors.grey300),
            ],
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: color.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.description ?? txn.typeLabel,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$dateStr  $timeStr',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                            if (txn.paymentMode != 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  txn.paymentModeLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'}${AppConstants.currencySymbol}${txn.totalAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.h4.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.l10n.balAfter(
                          txn.balanceAfter.abs().toStringAsFixed(0),
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey500,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- OVERVIEW TAB ----
  Widget _buildOverviewTab(
    bool isDark,
    CustomerModel customer,
    double totalCredit,
    double totalPayment,
    List<TransactionModel> transactions,
  ) {
    final creditPercent = totalCredit > 0 ? (totalPayment / totalCredit) : 0.0;

    // Compute monthly activity from real transactions
    final now = DateTime.now();
    final monthlyData = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(month);
      monthlyData[key] = 0;
    }
    for (final txn in transactions) {
      final key = DateFormat('MMM').format(txn.timestamp);
      if (monthlyData.containsKey(key)) {
        monthlyData[key] = (monthlyData[key] ?? 0) + txn.totalAmount;
      }
    }
    final maxMonthly = monthlyData.values.fold<double>(
      1,
      (max, v) => v > max ? v : max,
    );

    // Compute trust breakdown from real data
    final paymentRatio = totalCredit > 0
        ? (totalPayment / totalCredit).clamp(0.0, 1.0)
        : 0.5;

    final daysSinceJoining = DateTime.now()
        .difference(customer.createdAt)
        .inDays;
    final relationshipScore = (daysSinceJoining / 365).clamp(0.0, 1.0);

    final creditUtil = customer.creditLimit > 0
        ? (1.0 - (customer.currentBalance / customer.creditLimit)).clamp(
            0.0,
            1.0,
          )
        : 0.5;

    // Timeliness approximation based on trust score and payment ratio
    final timelinessScore =
        ((customer.trustScore / 100) * 0.5 + paymentRatio * 0.5).clamp(
          0.0,
          1.0,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Summary cards
          AnimatedListItem(
            index: 0,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context.l10n.totalCredit,
                    '${AppConstants.currencySymbol}${totalCredit.toStringAsFixed(0)}',
                    Icons.trending_up,
                    AppColors.error,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context.l10n.totalPaid,
                    '${AppConstants.currencySymbol}${totalPayment.toStringAsFixed(0)}',
                    Icons.trending_down,
                    AppColors.success,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment progress
          AnimatedListItem(
            index: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.paymentProgress,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(creditPercent * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: creditPercent.clamp(0.0, 1.0),
                      ),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 12,
                          backgroundColor: AppColors.grey200,
                          valueColor: AlwaysStoppedAnimation(
                            value > 0.8
                                ? AppColors.success
                                : value > 0.5
                                ? AppColors.warning
                                : AppColors.error,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.paidAmount(
                          '${AppConstants.currencySymbol}${totalPayment.toStringAsFixed(0)}',
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        context.l10n.remainingAmount(
                          '${AppConstants.currencySymbol}${customer.currentBalance.abs().toStringAsFixed(0)}',
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly trend (from real transaction data)
          AnimatedListItem(
            index: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.monthlyActivity,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlyData.entries.toList().asMap().entries.map(
                        (entry) {
                          final monthLabel = entry.value.key;
                          final value = entry.value.value;
                          final height = maxMonthly > 0
                              ? value / maxMonthly
                              : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (value > 0)
                                    Text(
                                      '₹${(value / 1000).toStringAsFixed(1)}K',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: height),
                                    duration: Duration(
                                      milliseconds: 600 + (entry.key * 100),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, _) {
                                      return Container(
                                        height: 80 * v,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryLight,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    monthLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trust score breakdown (computed from real data)
          AnimatedListItem(
            index: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.trustScoreBreakdown,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTrustFactor(
                    context.l10n.paymentHistoryLabel,
                    paymentRatio,
                    AppColors.success,
                  ),
                  _buildTrustFactor(
                    context.l10n.paymentTimeliness,
                    timelinessScore,
                    AppColors.warning,
                  ),
                  _buildTrustFactor(
                    context.l10n.creditUtilization,
                    creditUtil,
                    AppColors.info,
                  ),
                  _buildTrustFactor(
                    context.l10n.relationshipLabel,
                    relationshipScore,
                    AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.navClearance),
        ],
      ),
    );
  }

  Widget _buildTrustFactor(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  // ---- DETAILS TAB ----
  Widget _buildDetailsTab(bool isDark, CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AnimatedListItem(
            index: 0,
            child: _buildInfoSection(context.l10n.contactInformation, [
              _InfoItem(Icons.phone, context.l10n.phone, customer.phone),
              _InfoItem(
                Icons.email,
                context.l10n.emailLabel,
                customer.email ?? context.l10n.notProvided,
              ),
              _InfoItem(
                Icons.location_on,
                context.l10n.address,
                customer.address ?? context.l10n.notProvided,
              ),
            ], isDark),
          ),
          const SizedBox(height: 16),
          AnimatedListItem(
            index: 1,
            child: _buildInfoSection(context.l10n.accountInformation, [
              _InfoItem(
                Icons.calendar_today,
                context.l10n.customerSinceLabel,
                DateFormat('dd MMM yyyy').format(customer.createdAt),
              ),
              _InfoItem(
                Icons.access_time,
                context.l10n.lastActivity,
                customer.lastTransactionAt != null
                    ? _formatRelativeDate(customer.lastTransactionAt!)
                    : context.l10n.noActivity,
              ),
              _InfoItem(
                Icons.credit_card,
                context.l10n.creditLimitLabel,
                '${AppConstants.currencySymbol}${customer.creditLimit.toStringAsFixed(0)}',
              ),
              _InfoItem(
                Icons.star,
                context.l10n.trustScore,
                '${customer.trustScore}/100 (${customer.trustLevel})',
              ),
            ], isDark),
          ),
          const SizedBox(height: 16),
          if (customer.notes != null && customer.notes!.isNotEmpty)
            AnimatedListItem(
              index: 2,
              child: _buildInfoSection(context.l10n.notesSection, [
                _InfoItem(
                  Icons.notes,
                  context.l10n.notesSection,
                  customer.notes!,
                ),
              ], isDark),
            ),
          const SizedBox(height: 16),
          AnimatedListItem(
            index: 3,
            child: _buildQuickActions(isDark, customer),
          ),
          const SizedBox(height: AppSpacing.navClearance),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoItem> items, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, CustomerModel customer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.quickActions,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  Icons.call,
                  context.l10n.callCustomer,
                  AppColors.success,
                  () => _launchUrl('tel:${customer.phone}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  Icons.message,
                  context.l10n.sms,
                  AppColors.info,
                  () => _launchUrl('sms:${customer.phone}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  Icons.share,
                  context.l10n.share,
                  AppColors.secondary,
                  () => _shareCustomerInfo(customer),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  Icons.undo,
                  context.l10n.undo,
                  AppColors.warning,
                  () {
                    context.read<TransactionBloc>().add(
                      UndoLastTransaction(widget.customerId),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.lastTransactionUndone),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final iconSize = context.responsive.quickActionIconSize;
    return AnimatedScaleOnTap(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: iconSize * 0.46),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push(RouteConstants.addTransaction, extra: widget.customerId);
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: AppColors.white),
      label: Text(
        context.l10n.addNewTransaction,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _shareCustomerInfo(CustomerModel customer) {
    final balance = customer.currentBalance > 0
        ? '₹${customer.currentBalance.toStringAsFixed(0)} pending'
        : 'No dues';
    final text =
        'Customer: ${customer.name}\nPhone: ${customer.phone}\nBalance: $balance';
    Share.share(text);
  }

  void _showOptionsSheet(CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  Icons.receipt_long,
                  context.l10n.sendStatement,
                  AppColors.primary,
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Capture context-dependent values before async gaps
                    final txnBloc = context.read<TransactionBloc>();
                    final l10n = context.l10n;
                    final locale = Localizations.localeOf(context).languageCode;
                    try {
                      final secureStorage = getIt<SecureStorageService>();
                      final shopName = await secureStorage.read('shop_name') ?? 'My Shop';

                      final txnState = txnBloc.state;
                      List<TransactionModel> transactions = [];
                      if (txnState is TransactionLoaded) {
                        transactions = txnState.transactions;
                      }

                      final reportTxns = transactions.map((t) => ReportTransaction(
                        id: t.id,
                        customerName: customer.name,
                        type: t.transactionType.name, // 'credit' or 'payment'
                        amount: t.totalAmount,
                        date: t.timestamp,
                        description: t.description ?? '',
                      )).toList();

                      final now = DateTime.now();
                      final startDate = transactions.isNotEmpty
                          ? transactions.last.timestamp
                          : now.subtract(const Duration(days: 30));

                      final bytes = await PdfReportService.generateCustomerStatement(
                        shopName: shopName,
                        customerName: customer.name,
                        customerPhone: customer.phone,
                        startDate: startDate,
                        endDate: now,
                        transactions: reportTxns,
                        openingBalance: 0,
                        closingBalance: customer.currentBalance,
                        l10n: l10n,
                        locale: locale,
                      );

                      await PdfReportService.shareReport(
                        Uint8List.fromList(bytes),
                        'statement_${customer.name.replaceAll(' ', '_')}.pdf',
                        l10n: l10n,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                ),
                _buildOptionTile(
                  Icons.download,
                  context.l10n.exportData,
                  AppColors.info,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final txnState = context.read<TransactionBloc>().state;
                      List<TransactionModel> transactions = [];
                      if (txnState is TransactionLoaded) {
                        transactions = txnState.transactions;
                      }

                      final exportData = {
                        'customer': {
                          'id': customer.id,
                          'name': customer.name,
                          'phone': customer.phone,
                          'email': customer.email,
                          'currentBalance': customer.currentBalance,
                          'creditLimit': customer.creditLimit,
                          'createdAt': customer.createdAt.toIso8601String(),
                        },
                        'transactions': transactions.map((t) => {
                          'id': t.id,
                          'type': t.isCredit ? 'credit' : 'debit',
                          'amount': t.totalAmount,
                          'description': t.description,
                          'createdAt': t.timestamp.toIso8601String(),
                        }).toList(),
                      };
                      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
                      final tempDir = await getTemporaryDirectory();
                      final file = File('${tempDir.path}/customer_${customer.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json');
                      await file.writeAsString(jsonString);
                      await Share.shareXFiles([XFile(file.path)], subject: 'Customer Data - ${customer.name}');
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                ),
                _buildOptionTile(
                  Icons.edit,
                  context.l10n.editCustomer,
                  AppColors.warning,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/customers/${customer.id}/edit', extra: customer);
                  },
                ),
                _buildOptionTile(
                  Icons.delete_outline,
                  context.l10n.deleteCustomerLabel,
                  AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(customer);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteCustomerTitle),
        content: Text(context.l10n.deleteCustomerMessage(customer.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CustomerBloc>().add(DeleteCustomer(customer.id));
              context.pop();
            },
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return DateFormat('dd MMM').format(date);
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(date);
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);
}
