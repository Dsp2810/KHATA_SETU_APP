import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/premium_animations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/customer_card.dart';
import '../../../../shared/widgets/transaction_card.dart';
import '../../../../features/customers/presentation/bloc/customer_bloc.dart';
import '../../../../features/customers/presentation/bloc/customer_event.dart';
import '../../../../features/customers/presentation/bloc/customer_state.dart';
import '../../../../features/ledger/presentation/bloc/transaction_bloc.dart';
import '../../../../features/ledger/presentation/bloc/transaction_event.dart';
import '../../../../features/ledger/presentation/bloc/transaction_state.dart';
import '../../../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../../../features/notifications/presentation/bloc/notification_state.dart';
import '../bloc/dashboard_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String _selectedShop = '';
  int _selectedChartPeriod = 0;
  int _touchedPieIndex = -1;
  List<Map<String, dynamic>> _shops = [];

  late AnimationController _animController;
  late AnimationController _chartAnimController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _chartAnimController.forward();
    });

    // Load real data
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<TransactionBloc>().add(LoadAllTransactions());
    context.read<DashboardCubit>().loadShopInfo();
  }

  @override
  void dispose() {
    _animController.dispose();
    _chartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocListener<DashboardCubit, DashboardState>(
            listener: (context, dashState) {
              if (dashState is DashboardShopLoaded) {
                setState(() {
                  _selectedShop = dashState.shopName;
                  _shops = dashState.shops;
                });
              }
            },
            child: BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, custState) {
              return BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, txnState) {
                  // Show loading spinner if both BLoCs are still in initial state
                  if (custState is CustomerLoading ||
                      txnState is TransactionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show error with retry if either BLoC has an error
                  if (custState is CustomerError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 56,
                              color: AppColors.error.withValues(alpha: 0.6)),
                          const SizedBox(height: 16),
                          Text(custState.message,
                              style: const TextStyle(fontSize: 14, color: AppColors.grey500),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _onRefresh(context),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final customers = custState is CustomerLoaded
                      ? custState.customers
                      : <CustomerModel>[];
                  final allTransactions = txnState is AllTransactionsLoaded
                      ? txnState.transactions
                      : <TransactionModel>[];

                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    color: AppColors.primaryLight,
                    backgroundColor: context.cardColor,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(isDark),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.navClearance,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              AnimatedListItem(
                                index: 0,
                                child: _buildHeroCard(isDark, allTransactions),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 1,
                                child: _buildStatsGrid(
                                  isDark,
                                  customers,
                                  allTransactions,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 2,
                                child: _buildRevenueChart(
                                  isDark,
                                  allTransactions,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 3,
                                child: _buildCategoryBreakdown(
                                  isDark,
                                  allTransactions,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 4,
                                child: _buildQuickActions(isDark),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 6,
                                child: _buildTopDefaulters(isDark, customers),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedListItem(
                                index: 7,
                                child: _buildRecentTransactions(
                                  isDark,
                                  allTransactions,
                                  customers,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          ), // BlocListener
        ),
      ),
    );
  }

  // ─────────────────────── App Bar ───────────────────────
  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 68,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      titleSpacing: AppSpacing.md,
      title: FadeTransition(
        opacity: _animController,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animController,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _selectedShop,
                      style: AppTextStyles.h3.copyWith(
                        color: context.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Shop Switcher — Glass Pill
        SpringContainer(
          onTap: _showShopSwitcher,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: context.glassGradient,
              borderRadius: BorderRadius.circular(AppRadius.circular),
              border: Border.all(color: context.glassBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) =>
                      AppGradients.primaryGradient.createShader(b),
                  child: const Icon(Icons.store_rounded, size: 16),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive.shopNameMaxWidth,
                  ),
                  child: Text(
                    _selectedShop,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),

        // Notification bell
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, notifState) {
            final unreadCount = notifState is NotificationLoaded
                ? notifState.unreadCount
                : 0;
            return SpringContainer(
              onTap: () => context.push(RouteConstants.notifications),
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      unreadCount > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_outlined,
                      color: context.textPrimaryColor,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '${context.l10n.goodMorning},';
    if (hour < 17) return '${context.l10n.goodAfternoon},';
    return '${context.l10n.goodEvening},';
  }

  // ─────────────────────── Hero Card ───────────────────────
  Widget _buildHeroCard(bool isDark, List<TransactionModel> allTransactions) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTxns = allTransactions
        .where((t) => t.timestamp.isAfter(todayStart))
        .toList();

    final todayCollection = todayTxns
        .where((t) => t.isDebit)
        .fold<double>(0, (s, t) => s + t.totalAmount);
    final todayCredit = todayTxns
        .where((t) => t.isCredit)
        .fold<double>(0, (s, t) => s + t.totalAmount);
    final todayNet = todayCollection + todayCredit;
    final txnCount = todayTxns.length;

    // Yesterday comparison
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayTxns = allTransactions
        .where(
          (t) =>
              t.timestamp.isAfter(yesterdayStart) &&
              t.timestamp.isBefore(todayStart),
        )
        .toList();
    final yesterdayNet = yesterdayTxns.fold<double>(
      0,
      (s, t) => s + t.totalAmount,
    );
    final percentChange = yesterdayNet > 0
        ? ((todayNet - yesterdayNet) / yesterdayNet * 100)
        : 0.0;

    return GlassCard(
      padding: EdgeInsets.zero,
      gradient: AppGradients.primaryGradient,
      borderColor: Colors.white.withValues(alpha: 0.15),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.account_balance_wallet,
              size: 140,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadius.circular,
                              ),
                            ),
                            child: Text(
                              context.l10n.todaySummary,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CountingText(
                        value: todayNet,
                        prefix: '₹',
                        style: AppTextStyles.display.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (yesterdayNet > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (percentChange >= 0
                                            ? Colors.greenAccent
                                            : AppColors.error)
                                        .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    percentChange >= 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 12,
                                    color: percentChange >= 0
                                        ? Colors.greenAccent
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: percentChange >= 0
                                          ? Colors.greenAccent
                                          : AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.l10n.fromYesterday,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Transaction count circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$txnCount',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Txns',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Stats Grid ───────────────────────
  Widget _buildStatsGrid(
    bool isDark,
    List<CustomerModel> customers,
    List<TransactionModel> allTransactions,
  ) {
    final totalPending = customers.fold<double>(
      0,
      (s, c) => c.currentBalance > 0 ? s + c.currentBalance : s,
    );
    final owingCount = customers.where((c) => c.owesUs).length;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTxns = allTransactions
        .where((t) => t.timestamp.isAfter(todayStart))
        .toList();
    final todayCollection = todayTxns
        .where((t) => t.isDebit)
        .fold<double>(0, (s, t) => s + t.totalAmount);
    final todayTxnCount = todayTxns.length;

    // Yesterday's collection for trend calculation
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayCollection = allTransactions
        .where(
          (t) =>
              t.timestamp.isAfter(yesterdayStart) &&
              t.timestamp.isBefore(todayStart) &&
              t.isDebit,
        )
        .fold<double>(0, (s, t) => s + t.totalAmount);
    final collectionTrend = yesterdayCollection > 0
        ? ((todayCollection - yesterdayCollection) / yesterdayCollection) * 100
        : (todayCollection > 0 ? 100.0 : null);

    final totalCustomers = customers.length;
    final activeToday = customers
        .where(
          (c) =>
              c.lastTransactionAt != null &&
              c.lastTransactionAt!.isAfter(todayStart),
        )
        .length;

    String formatCompact(double value) {
      if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
      if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
      return '₹${value.toStringAsFixed(0)}';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SpringContainer(
                onTap: () => context.go(RouteConstants.ledger),
                child: _GlassStatCard(
                  title: context.l10n.totalOutstanding,
                  value: formatCompact(totalPending),
                  subtitle: context.l10n.totalCustomersCount(owingCount),
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: AppGradients.dangerGradient,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SpringContainer(
                onTap: () => context.go(RouteConstants.ledger),
                child: _GlassStatCard(
                  title: context.l10n.todayCollection,
                  value: formatCompact(todayCollection),
                  subtitle: context.l10n.transactionCount(todayTxnCount),
                  icon: Icons.payments_outlined,
                  gradient: AppGradients.successGradient,
                  trend: collectionTrend,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SpringContainer(
                onTap: () => context.go(RouteConstants.customers),
                child: _GlassStatCard(
                  title: context.l10n.totalCustomers,
                  value: '$totalCustomers',
                  subtitle:
                      '$activeToday ${context.l10n.activeCustomers.toLowerCase()}',
                  icon: Icons.people_outline_rounded,
                  gradient: AppGradients.primaryGradient,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SpringContainer(
                onTap: () => context.go(RouteConstants.inventory),
                child: _GlassStatCard(
                  title: context.l10n.totalTransactions,
                  value: '${allTransactions.length}',
                  subtitle: context.l10n.allTime,
                  icon: Icons.receipt_long_outlined,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.7),
                    ],
                  ),
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────── Revenue Chart ───────────────────────
  Widget _buildRevenueChart(
    bool isDark,
    List<TransactionModel> allTransactions,
  ) {
    // Compute last 7 days of data
    final now = DateTime.now();
    final dayLabels = <String>[];
    final collectionData = <double>[];
    final creditData = <double>[];
    double maxY = 1000;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      dayLabels.add(DateFormat('E').format(date).substring(0, 3));

      final dayTxns = allTransactions.where(
        (t) => t.timestamp.isAfter(dayStart) && t.timestamp.isBefore(dayEnd),
      );

      final collection = dayTxns
          .where((t) => t.isDebit)
          .fold<double>(0, (s, t) => s + t.totalAmount);
      final credit = dayTxns
          .where((t) => t.isCredit)
          .fold<double>(0, (s, t) => s + t.totalAmount);

      collectionData.add(collection);
      creditData.add(credit);

      if (collection > maxY) maxY = collection;
      if (credit > maxY) maxY = credit;
    }

    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 1000) maxY = 1000;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.revenueOverview,
                      style: AppTextStyles.h4.copyWith(
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: _buildChartLegend(
                            context.l10n.paymentReceived,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: _buildChartLegend(
                            context.l10n.creditGiven,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildChartPeriodSelector(isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedBuilder(
            animation: _chartAnimController,
            builder: (context, child) {
              return SizedBox(
                height: context.responsive.chartHeight,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '₹${rod.toY.toStringAsFixed(0)}',
                            AppTextStyles.caption.copyWith(
                              color: AppColors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dayLabels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayLabels[idx],
                                style: AppTextStyles.caption.copyWith(
                                  color: context.textSecondaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}K',
                              style: AppTextStyles.caption.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: context.dividerColor,
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY:
                                collectionData[index] *
                                _chartAnimController.value,
                            gradient: AppGradients.successGradient,
                            width: context.responsive.isSmallPhone ? 7 : 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                          BarChartRodData(
                            toY: creditData[index] * _chartAnimController.value,
                            gradient: AppGradients.dangerGradient,
                            width: context.responsive.isSmallPhone ? 7 : 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Category Breakdown ───────────────────────
  Widget _buildCategoryBreakdown(
    bool isDark,
    List<TransactionModel> allTransactions,
  ) {
    // Group credit transactions by description keyword categories
    final creditTxns = allTransactions.where((t) => t.isCredit).toList();

    if (creditTxns.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.categoryBreakdown,
              style: AppTextStyles.h4.copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  context.l10n.noCreditTransactionsYet,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Categorize by items or description
    final categoryMap = <String, double>{};
    for (final txn in creditTxns) {
      if (txn.items.isNotEmpty) {
        for (final item in txn.items) {
          final cat = item.name;
          categoryMap[cat] = (categoryMap[cat] ?? 0) + item.total;
        }
      } else {
        final cat = txn.description ?? 'Others';
        categoryMap[cat] = (categoryMap[cat] ?? 0) + txn.totalAmount;
      }
    }

    // Sort by value and take top 5
    final sorted = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final totalCat = top.fold<double>(0, (s, e) => s + e.value);

    final catColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.neonCyan,
      AppColors.warning,
      AppColors.grey500,
    ];

    final categories = top.asMap().entries.map((entry) {
      final percent = totalCat > 0
          ? (entry.value.value / totalCat * 100).round()
          : 0;
      return {
        'name': entry.value.key,
        'value': entry.value.value,
        'color': catColors[entry.key % catColors.length],
        'percent': percent,
      };
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.categoryBreakdown,
            style: AppTextStyles.h4.copyWith(color: context.textPrimaryColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                height: context.responsive.pieChartSize,
                width: context.responsive.pieChartSize,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 35,
                    sections: categories.asMap().entries.map((entry) {
                      final isTouched = entry.key == _touchedPieIndex;
                      return PieChartSectionData(
                        value: entry.value['value'] as double,
                        color: entry.value['color'] as Color,
                        radius: isTouched ? 35.0 : 28.0,
                        title: '',
                        borderSide: isTouched
                            ? BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              )
                            : BorderSide.none,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.asMap().entries.map((entry) {
                    final isHighlighted = entry.key == _touchedPieIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isHighlighted ? 8 : 0,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? (entry.value['color'] as Color).withValues(
                                  alpha: 0.12,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: entry.value['color'] as Color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (entry.value['color'] as Color)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value['name'] as String,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.textPrimaryColor,
                                  fontWeight: isHighlighted
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.value['percent']}%',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: entry.value['color'] as Color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartPeriodSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: context.glassColor,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        children: [context.l10n.week, context.l10n.month, context.l10n.year]
            .asMap()
            .entries
            .map((entry) {
              final isSelected = _selectedChartPeriod == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedChartPeriod = entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.primaryGradient : null,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    entry.value,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : context.textSecondaryColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Quick Actions ───────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.quickActions,
          style: AppTextStyles.h4.copyWith(color: context.textPrimaryColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.person_add_outlined,
                label: context.l10n.addCustomer,
                gradient: AppGradients.primaryGradient,
                onTap: () => context.push(RouteConstants.addCustomer),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.add_shopping_cart_rounded,
                label: context.l10n.newSale,
                gradient: AppGradients.successGradient,
                onTap: () => context.go(RouteConstants.inventory),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.payments_outlined,
                label: context.l10n.collectPayment,
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonCyan,
                    AppColors.neonCyan.withValues(alpha: 0.7),
                  ],
                ),
                onTap: () => context.go(RouteConstants.ledger),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.bar_chart_rounded,
                label: context.l10n.reports,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.7),
                  ],
                ),
                onTap: () => context.push('/reports'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.menu_book_rounded,
                label: context.l10n.dailyBook,
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning,
                    AppColors.warning.withValues(alpha: 0.7),
                  ],
                ),
                onTap: () => context.push(RouteConstants.dailyNotebook),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GlassQuickAction(
                icon: Icons.receipt_long_rounded,
                label: context.l10n.billing,
                gradient: LinearGradient(
                  colors: [
                    AppColors.info,
                    AppColors.info.withValues(alpha: 0.7),
                  ],
                ),
                onTap: () => context.push(RouteConstants.billing),
              ),
            ),
            const Expanded(child: SizedBox()),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  // ─────────────────────── Top Defaulters ───────────────────────
  Widget _buildTopDefaulters(bool isDark, List<CustomerModel> customers) {
    // Sort by balance desc, take top 5 who owe
    final defaulters = customers.where((c) => c.owesUs).toList()
      ..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
    final topDefaulters = defaulters.take(5).toList();

    if (topDefaulters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      context.l10n.topDebtors,
                      style: AppTextStyles.h4.copyWith(
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GradientBadge(
                    label: '${topDefaulters.length}',
                    gradient: AppGradients.dangerGradient,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go(RouteConstants.customers),
              child: Text(
                context.l10n.viewAll,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...topDefaulters.map(
          (c) => CustomerCard(
            name: c.name,
            phone: c.phone,
            balance: c.currentBalance,
            riskScore: c.trustScore,
            lastTransaction: c.lastTransactionAt,
            onTap: () => context.push('/customers/${c.id}'),
            onCall: () {},
            onMessage: () {},
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Recent Transactions ───────────────────────
  Widget _buildRecentTransactions(
    bool isDark,
    List<TransactionModel> allTransactions,
    List<CustomerModel> customers,
  ) {
    // Take last 5 transactions
    final recent = allTransactions.take(5).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build a customer id → name map for lookups
    final custMap = <String, String>{for (final c in customers) c.id: c.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                context.l10n.recentTransactions,
                style: AppTextStyles.h4.copyWith(
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go(RouteConstants.ledger),
              child: Text(
                context.l10n.viewAll,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recent.map((txn) {
          final customerName = custMap[txn.customerId] ?? 'Unknown';
          return TransactionCard(
            customerName: customerName,
            amount: txn.totalAmount,
            type: txn.transactionType,
            paymentMode: _mapPaymentMode(txn.paymentMode),
            date: txn.timestamp,
            description: txn.description,
            productName: txn.items.isNotEmpty ? txn.items.first.name : null,
          );
        }),
      ],
    );
  }

  PaymentMode _mapPaymentMode(int mode) {
    switch (mode) {
      case 1:
        return PaymentMode.upi;
      case 2:
        return PaymentMode.bank;
      case 3:
        return PaymentMode.other;
      default:
        return PaymentMode.cash;
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    HapticFeedback.mediumImpact();
    _chartAnimController.reset();
    context.read<CustomerBloc>().add(RefreshCustomers());
    context.read<TransactionBloc>().add(LoadAllTransactions());
    context.read<DashboardCubit>().loadShopInfo();
    await Future.delayed(const Duration(milliseconds: 300));
    _chartAnimController.forward();
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showShopSwitcher() {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.selectShop,
              style: AppTextStyles.h3.copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_shops.isEmpty)
              _ShopTile(
                name: _selectedShop.isNotEmpty ? _selectedShop : 'My Shop',
                address: '',
                isSelected: true,
                onTap: () => Navigator.pop(ctx),
              )
            else
              ..._shops.map((shop) {
                final name = (shop['name'] ?? '').toString();
                final address = (shop['address'] ?? '').toString();
                return _ShopTile(
                  name: name,
                  address: address,
                  isSelected: _selectedShop == name,
                  onTap: () {
                    setState(() => _selectedShop = name);
                    Navigator.pop(ctx);
                  },
                );
              }),
            const SizedBox(height: AppSpacing.md),
            MorphingGradientButton(
              label: context.l10n.addNewShop,
              icon: Icons.add_rounded,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.shopManagementComingSoon),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              width: double.infinity,
              height: 48,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primaryLight.withValues(alpha: 0.6),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ Supporting Widgets ═══════════════════════

class _GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final double? trend;
  final bool isDark;

  const _GlassStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBox(
                icon: icon,
                gradient: gradient,
                size: 36,
                iconSize: 18,
                borderRadius: 10,
              ),
              if (trend != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (trend! > 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 10,
                        color: trend! > 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend!.abs().toStringAsFixed(1)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: trend! > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: context.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: context.textSecondaryColor,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GlassQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _GlassQuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringContainer(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          children: [
            GradientIconBox(
              icon: icon,
              gradient: gradient,
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 10,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final String name;
  final String address;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShopTile({
    required this.name,
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        borderColor: isSelected ? AppColors.primary.withValues(alpha: 0.5) : null,
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              )
            : null,
        child: Row(
          children: [
            GradientIconBox(
              icon: Icons.store_rounded,
              gradient: isSelected
                  ? AppGradients.primaryGradient
                  : LinearGradient(
                      colors: [AppColors.grey500, AppColors.grey400],
                    ),
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    address,
                    style: AppTextStyles.caption.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }
}
