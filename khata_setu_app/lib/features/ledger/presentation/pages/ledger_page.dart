import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/ledger_rules.dart';

import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/premium_animations.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/presentation/bloc/customer_event.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

/// Ledger Page — Daily notebook/diary view.
///
/// Shows real transactions from Hive grouped by date, with timestamps,
/// customer names, and a daily summary per date group. Like a real
/// shopkeeper's khata notebook.
class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  late AnimationController _headerAnimController;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Dispatch loading events on the global singletons
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionBloc>().add(LoadAllTransactions());
      context.read<CustomerBloc>().add(LoadCustomers());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  // ─── Date helpers ──────────────────────────────────────────────

  String _getDateLabel(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return context.l10n.today;
    if (dateKey == yesterday) return context.l10n.yesterday;

    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('EEEE, d MMMM').format(date);
    } catch (_) {
      return dateKey;
    }
  }

  String _getDateSubtitle(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (dateKey == today) return DateFormat('d MMMM yyyy').format(now);

    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('d MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  // ─── Filtering ─────────────────────────────────────────────────

  Map<String, List<TransactionModel>> _applyFilters(
      Map<String, List<TransactionModel>> grouped) {
    final result = <String, List<TransactionModel>>{};
    final query = _searchController.text.toLowerCase();

    for (final entry in grouped.entries) {
      var txns = entry.value;

      // Text search (by customer name or description)
      if (query.isNotEmpty) {
        txns = txns.where((t) {
          final customer = _findCustomer(t.customerId);
          final name = customer?.name.toLowerCase() ?? '';
          final desc = t.description?.toLowerCase() ?? '';
          return name.contains(query) || desc.contains(query);
        }).toList();
      }

      // Type filter
      if (_selectedFilter == 'credit') {
        txns = txns.where((t) => t.transactionType == TransactionType.credit).toList();
      } else if (_selectedFilter == 'debit') {
        txns = txns.where((t) => t.transactionType == TransactionType.payment).toList();
      }

      // Date range filter
      if (_dateRange != null) {
        txns = txns.where((t) =>
            t.timestamp.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1))) &&
            t.timestamp
                .isBefore(_dateRange!.end.add(const Duration(days: 1))))
            .toList();
      }

      if (txns.isNotEmpty) {
        result[entry.key] = txns;
      }
    }
    return result;
  }

  CustomerModel? _findCustomer(String customerId) {
    final state = context.read<CustomerBloc>().state;
    if (state is CustomerLoaded) {
      try {
        return state.customers.firstWhere((c) => c.id == customerId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          // After a new transaction is added from add page, reload
          if (state is TransactionAdded) {
            context.read<TransactionBloc>().add(LoadAllTransactions());
            context.read<CustomerBloc>().add(LoadCustomers());
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AmbientBackground(
            child: SafeArea(
              bottom: false,
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, customerState) {
                  return BlocBuilder<TransactionBloc, TransactionState>(
                    buildWhen: (prev, curr) =>
                        curr is AllTransactionsLoaded ||
                        curr is TransactionLoading ||
                        curr is TransactionInitial ||
                        curr is TransactionError,
                    builder: (context, txnState) {
                      if (txnState is AllTransactionsLoaded) {
                        return _buildLedgerContent(context, txnState);
                      }
                      if (txnState is TransactionLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (txnState is TransactionError) {
                        return Column(
                          children: [
                            _buildHeader(context.isDark),
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 56,
                                        color: AppColors.error.withValues(alpha: 0.6)),
                                    const SizedBox(height: 16),
                                    Text(txnState.message,
                                        style: const TextStyle(fontSize: 14, color: AppColors.grey500),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () => context.read<TransactionBloc>()
                                          .add(LoadAllTransactions()),
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: Text(context.l10n.retry),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      // Initial state — show empty notebook
                      return _buildEmptyNotebook(context);
                    },
                  );
                },
              ),
            ),
          ),
          // FAB removed - using inline button instead
        ),
    );
  }

  Widget _buildEmptyNotebook(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.grey300),
                const SizedBox(height: 16),
                Text(context.l10n.khataEmpty,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                        color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text(context.l10n.tapToAddFirstEntry,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey400)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerContent(
      BuildContext context, AllTransactionsLoaded state) {
    final isDark = context.isDark;
    final filtered = _applyFilters(state.groupedByDate);
    final sortedDateKeys = filtered.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Compute stats from filtered results
    final allTxns = filtered.values.expand((list) => list).toList();
    final totalCredit = allTxns.fold(0.0, (s, t) =>
        s + (t.transactionType == TransactionType.credit ? t.totalAmount : 0));
    final totalPayment = allTxns.fold(0.0, (s, t) =>
        s + (t.transactionType == TransactionType.payment ? t.totalAmount : 0));

    return Column(
      children: [
        _buildHeader(isDark),
        _buildNotebookSummary(
            isDark, totalCredit, totalPayment, allTxns.length),
        _buildAddTransactionButton(isDark),
        _buildFilters(isDark, state),
        Expanded(
          child: sortedDateKeys.isEmpty
              ? PremiumEmptyState(
                  icon: Icons.menu_book_rounded,
                  title: context.l10n.noMatchingEntries,
                  subtitle: context.l10n.adjustSearchOrFilters,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<TransactionBloc>().add(LoadAllTransactions());
                    context.read<CustomerBloc>().add(LoadCustomers());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.navClearance),
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    itemCount: sortedDateKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDateKeys[index];
                      final dayTxns = filtered[dateKey]!;
                      return AnimatedListItem(
                        index: index,
                        child: _DailyNotebookSection(
                          dateLabel: _getDateLabel(dateKey),
                          dateSubtitle: _getDateSubtitle(dateKey),
                          transactions: dayTxns,
                          findCustomer: _findCustomer,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.khataBook,
                      style: AppTextStyles.h2
                          .copyWith(color: context.textPrimaryColor)),
                  Text(context.l10n.yourDailyNotebook,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor)),
                ],
              ),
              const Spacer(),
              SpringContainer(
                onTap: () => context.push('/reports'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.glassColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.glassBorderColor),
                  ),
                  child: Icon(Icons.picture_as_pdf_outlined,
                      size: 20, color: context.textSecondaryColor),
                ),
              ),
              const SizedBox(width: 8),
              SpringContainer(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _dateRange != null
                        ? AppGradients.primaryGradient
                        : null,
                    color:
                        _dateRange != null ? null : context.glassColor,
                    borderRadius:
                        BorderRadius.circular(AppRadius.circular),
                    border: Border.all(
                        color: _dateRange != null
                            ? Colors.transparent
                            : context.glassBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14,
                          color: _dateRange != null
                              ? Colors.white
                              : context.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _dateRange != null
                            ? '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'
                            : context.l10n.allTime,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: _dateRange != null
                                ? Colors.white
                                : context.textSecondaryColor),
                      ),
                      if (_dateRange != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _dateRange = null;
                            context.read<TransactionBloc>().add(LoadAllTransactions());
                          }),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Search bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.glassGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchByCustomerOrDescription,
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: context.textSecondaryColor),
                    prefixIcon: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppGradients.primaryGradient.createShader(b),
                      child:
                          const Icon(Icons.search_rounded, size: 22),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: context.textSecondaryColor,
                                size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            })
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notebook Summary Card ─────────────────────────────────────

  Widget _buildNotebookSummary(
      bool isDark, double totalCredit, double totalPayment, int count) {
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: entries count + badge
                Row(
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppGradients.primaryGradient.createShader(b),
                      child: const Icon(
                          Icons.menu_book_rounded, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(context.l10n.entriesCount(count),
                        style: AppTextStyles.labelMedium.copyWith(
                            color: context.textSecondaryColor)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.glassColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: context.glassBorderColor),
                      ),
                      child: Text(
                        _dateRange != null ? context.l10n.filtered : context.l10n.allTime,
                        style: AppTextStyles.caption.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Credit | Payment | Net
                Row(
                  children: [
                    Expanded(
                        child: _SummaryItem(
                            label: context.l10n.creditGiven,
                            amount: totalCredit,
                            icon: Icons.arrow_upward_rounded,
                            color: AppColors.error)),
                    Container(width: 1, height: 40,
                        color: context.glassBorderColor),
                    Expanded(
                        child: _SummaryItem(
                            label: context.l10n.received,
                            amount: totalPayment,
                            icon: Icons.arrow_downward_rounded,
                            color: AppColors.success)),
                    Container(width: 1, height: 40,
                        color: context.glassBorderColor),
                    Expanded(
                        child: _SummaryItem(
                            label: context.l10n.net,
                            amount: totalCredit - totalPayment,
                            icon: Icons.account_balance_wallet_rounded,
                            color: (totalCredit - totalPayment) > 0
                                ? AppColors.error
                                : AppColors.success,
                            showSign: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filter chips ──────────────────────────────────────────────

  Widget _buildFilters(bool isDark, AllTransactionsLoaded state) {
    final allCount = state.transactions.length;
    final creditCount = state.transactions
        .where((t) => t.transactionType == TransactionType.credit)
        .length;
    final debitCount = state.transactions
        .where((t) => t.transactionType == TransactionType.payment)
        .length;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(
          top: AppSpacing.md, bottom: AppSpacing.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _FilterChip(
              label: context.l10n.allTypes,
              count: allCount,
              isSelected: _selectedFilter == 'all',
              onTap: () =>
                  setState(() => _selectedFilter = 'all')),
          _FilterChip(
              label: context.l10n.creditUdhar,
              count: creditCount,
              isSelected: _selectedFilter == 'credit',
              color: AppColors.error,
              icon: Icons.arrow_upward_rounded,
              onTap: () =>
                  setState(() => _selectedFilter = 'credit')),
          _FilterChip(
              label: context.l10n.paymentsLabel,
              count: debitCount,
              isSelected: _selectedFilter == 'debit',
              color: AppColors.success,
              icon: Icons.arrow_downward_rounded,
              onTap: () =>
                  setState(() => _selectedFilter = 'debit')),
        ],
      ),
    );
  }

  // ─── Date range picker ─────────────────────────────────────────

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate:
          DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary)),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  // ─── Add Transaction Button ────────────────────────────────────

  Widget _buildAddTransactionButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showTransactionTypeSheet,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.addEntry,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet to choose transaction type (Credit or Payment)
  void _showTransactionTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TransactionTypeBottomSheet(
        onCreditSelected: () {
          Navigator.pop(ctx);
          context.push('/ledger/add', extra: {'type': 'credit'});
        },
        onPaymentSelected: () {
          Navigator.pop(ctx);
          context.push('/ledger/add', extra: {'type': 'payment'});
        },
      ),
    );
  }
}

/// Bottom sheet for selecting transaction type
class _TransactionTypeBottomSheet extends StatelessWidget {
  final VoidCallback onCreditSelected;
  final VoidCallback onPaymentSelected;

  const _TransactionTypeBottomSheet({
    required this.onCreditSelected,
    required this.onPaymentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text(
              context.l10n.selectTransactionType,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Credit option (Customer takes goods on udhar)
            _TransactionTypeOption(
              icon: Icons.arrow_upward_rounded,
              iconColor: AppColors.error,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              title: context.l10n.addCredit,
              subtitle: context.l10n.customerTakesGoodsOnCredit,
              onTap: onCreditSelected,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Payment option (Customer pays money)
            _TransactionTypeOption(
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              title: context.l10n.addPayment,
              subtitle: context.l10n.customerPaysMoney,
              onTap: onPaymentSelected,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Single option in the transaction type sheet
class _TransactionTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TransactionTypeOption({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: context.glassBorderColor),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Daily Notebook Section — One "page" per date
// Shows: date header → daily summary strip → timeline of entries
// Like a shopkeeper writing down each sale as it happens throughout
// the day, then a total at the bottom.
// ═══════════════════════════════════════════════════════════════════

class _DailyNotebookSection extends StatelessWidget {
  final String dateLabel;
  final String dateSubtitle;
  final List<TransactionModel> transactions;
  final CustomerModel? Function(String) findCustomer;
  final bool isDark;

  const _DailyNotebookSection({
    required this.dateLabel,
    required this.dateSubtitle,
    required this.transactions,
    required this.findCustomer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by time — earliest first (natural diary order)
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Daily totals
    final dayCredit = sorted.fold(0.0, (s, t) =>
        s + (t.transactionType == TransactionType.credit ? t.totalAmount : 0));
    final dayPayment = sorted.fold(0.0, (s, t) =>
        s + (t.transactionType == TransactionType.payment ? t.totalAmount : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),

        // ── Date header ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(dateLabel,
                  style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (dateSubtitle.isNotEmpty)
              Flexible(
                child: Text(dateSubtitle,
                    style: AppTextStyles.caption.copyWith(
                        color: context.textSecondaryColor),
                    overflow: TextOverflow.ellipsis),
              ),
            const Spacer(),
            Text(context.l10n.entriesCount(sorted.length),
                style: AppTextStyles.caption.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 10)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── Daily summary strip ──
        _DailySummaryStrip(
            credit: dayCredit,
            payment: dayPayment,
            count: sorted.length),
        const SizedBox(height: AppSpacing.xs),

        // ── Timeline entries ──
        ...sorted.asMap().entries.map((entry) {
          final txn = entry.value;
          final customer = findCustomer(txn.customerId);
          final isLast = entry.key == sorted.length - 1;

          return _NotebookEntry(
            transaction: txn,
            customerName: customer?.name ?? 'Unknown',
            isLast: isLast,
            isDark: isDark,
          );
        }),

        // ── Day footer: total sell line ──
        Padding(
          padding: const EdgeInsets.only(
              left: 56, top: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.02),
              ]),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.summarize_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Day Total: ₹${_compact(dayCredit)} credit, ₹${_compact(dayPayment)} received',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Daily Summary Strip — Compact summary below date header
// ═══════════════════════════════════════════════════════════════════

class _DailySummaryStrip extends StatelessWidget {
  final double credit;
  final double payment;
  final int count;

  const _DailySummaryStrip({
    required this.credit,
    required this.payment,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final net = credit - payment;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.arrow_upward_rounded,
              size: 12, color: AppColors.error),
          const SizedBox(width: 3),
          Text('₹${_compact(credit)}',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.arrow_downward_rounded,
              size: 12, color: AppColors.success),
          const SizedBox(width: 3),
          Text('₹${_compact(payment)}',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (net > 0
                      ? AppColors.error
                      : net < 0
                          ? AppColors.success
                          : AppColors.grey400)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Net: ${net > 0 ? '+' : ''}₹${_compact(net.abs())}',
              style: AppTextStyles.caption.copyWith(
                  color: net > 0
                      ? AppColors.error
                      : net < 0
                          ? AppColors.success
                          : context.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Notebook Entry — Single transaction with timeline dot
//
// Layout:  [time]     [customer avatar | name + desc | amount]
//           [●]       [GlassCard with entry details        ]
//           [│]
//
// Like: "10:30 AM  Dhaval — ₹100 — Biscuits"
// ═══════════════════════════════════════════════════════════════════

class _NotebookEntry extends StatelessWidget {
  final TransactionModel transaction;
  final String customerName;
  final bool isLast;
  final bool isDark;

  const _NotebookEntry({
    required this.transaction,
    required this.customerName,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.transactionType == TransactionType.credit;
    final color = isCredit ? AppColors.error : AppColors.success;
    final time = DateFormat('hh:mm a').format(transaction.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column (time + dot + line) ──
          SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: AppTextStyles.caption.copyWith(
                        color: context.textSecondaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1)),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: context.glassBorderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // ── Entry card ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    // Customer avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: isCredit
                            ? AppGradients.dangerGradient
                            : AppGradients.successGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          customerName.isNotEmpty
                              ? customerName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Name + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(customerName,
                              style: AppTextStyles.labelMedium
                                  .copyWith(
                                      color: context
                                          .textPrimaryColor,
                                      fontWeight:
                                          FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (transaction.description != null &&
                              transaction
                                  .description!.isNotEmpty)
                            Text(transaction.description!,
                                style: AppTextStyles.caption
                                    .copyWith(
                                        color: context
                                            .textSecondaryColor),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis),
                          Row(
                            children: [
                              Icon(
                                  _paymentIcon(
                                      transaction.paymentMode),
                                  size: 10,
                                  color: context
                                      .textSecondaryColor),
                              const SizedBox(width: 3),
                              Text(
                                  transaction.paymentModeLabel,
                                  style: AppTextStyles.caption
                                      .copyWith(
                                          color: context
                                              .textSecondaryColor,
                                          fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount + balance
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isCredit ? '+' : '-'}₹${transaction.totalAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.labelLarge
                              .copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.glassColor,
                            borderRadius:
                                BorderRadius.circular(4),
                            border: Border.all(
                                color:
                                    context.glassBorderColor),
                          ),
                          child: Text(
                              'Bal: ₹${transaction.balanceAfter.toStringAsFixed(0)}',
                              style: AppTextStyles.caption
                                  .copyWith(
                                      color: context
                                          .textSecondaryColor,
                                      fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(int mode) {
    switch (mode) {
      case 1:
        return Icons.phone_android_rounded;
      case 2:
        return Icons.credit_card_rounded;
      case 3:
        return Icons.receipt_rounded;
      default:
        return Icons.money_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Summary Item — used in the top summary card
// ═══════════════════════════════════════════════════════════════════

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool showSign;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05)
            ]),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 4),
        CountingText(
          value: amount.abs(),
          prefix:
              '${showSign && amount > 0 ? '+' : ''}₹',
          formatAsCompact: true,
          style: AppTextStyles.labelLarge.copyWith(
              color: color, fontWeight: FontWeight.w800),
        ),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: context.textSecondaryColor,
                fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Filter Chip
// ═══════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: SpringContainer(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [
                    chipColor,
                    chipColor.withValues(alpha: 0.8)
                  ])
                : null,
            color: isSelected ? null : context.glassColor,
            borderRadius:
                BorderRadius.circular(AppRadius.circular),
            border: Border.all(
                color: isSelected
                    ? chipColor.withValues(alpha: 0.3)
                    : context.glassBorderColor),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: chipColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: -2)
                  ]
                : null,
          ),
          child:
              Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : context.textSecondaryColor),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : context.textSecondaryColor,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : context.glassBorderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.textSecondaryColor,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}
