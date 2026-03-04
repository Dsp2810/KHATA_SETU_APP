import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_formatter.dart';

import '../../../../core/data/models/customer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/premium_animations.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../../../features/ledger/presentation/bloc/transaction_bloc.dart';
import '../../../../features/ledger/presentation/bloc/transaction_event.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _sortBy = 'name';
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabController.forward();

    // Load customers from Hive via BLoC
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  List<CustomerModel> _applyFiltersAndSort(List<CustomerModel> customers) {
    var result = List<CustomerModel>.from(customers);

    // Filter
    switch (_selectedFilter) {
      case 'owing':
        result = result.where((c) => c.owesUs).toList();
      case 'owed':
        result = result.where((c) => c.currentBalance < 0).toList();
      case 'settled':
        result = result.where((c) => c.currentBalance == 0).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        result.sort((a, b) => a.name.compareTo(b.name));
      case 'balance':
        result.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
      case 'recent':
        result.sort((a, b) {
          final aDate = a.lastTransactionAt ?? a.createdAt;
          final bDate = b.lastTransactionAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              final allCustomers =
                  state is CustomerLoaded ? state.customers : <CustomerModel>[];
              final filtered = _applyFiltersAndSort(allCustomers);

              final totalOwing = allCustomers.where((c) => c.owesUs).length;
              final totalPending = allCustomers.fold<double>(
                  0.0,
                  (sum, c) =>
                      c.currentBalance > 0 ? sum + c.currentBalance : sum);

              return Column(
                children: [
                  _buildHeader(isDark),
                  _buildSummaryCards(
                      isDark, allCustomers.length, totalOwing, totalPending),
                  _buildFilters(isDark, allCustomers),
                  Expanded(
                    child: state is CustomerLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state is CustomerError
                            ? Center(
                                child: Text(state.message,
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.error)))
                            : filtered.isEmpty
                                ? PremiumEmptyState(
                                    icon: Icons.person_search_rounded,
                                    title: context.l10n.noCustomersFound,
                                    subtitle:
                                        context.l10n.adjustSearchOrFilters,
                                  )
                                : RefreshIndicator(
                                    onRefresh: () async {
                                      context
                                          .read<CustomerBloc>()
                                          .add(RefreshCustomers());
                                    },
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.xs,
                                        AppSpacing.md,
                                        AppSpacing.navClearance,
                                      ),
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                              parent:
                                                  BouncingScrollPhysics()),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final customer = filtered[index];
                                        return AnimatedListItem(
                                          index: index,
                                          child: _GlassCustomerCard(
                                            customer: customer,
                                            isDark: isDark,
                                            onTap: () => context.push(
                                                '/customers/${customer.id}'),
                                            onAddTransaction: () =>
                                                _showQuickTransactionSheet(
                                                    customer),
                                            onCall: () =>
                                                _callCustomer(customer),
                                            onMessage: () =>
                                                _messageCustomer(customer),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
            parent: _fabController, curve: Curves.elasticOut),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/customers/add'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text(context.l10n.addCustomer,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(context.l10n.customers,
                  style: AppTextStyles.h2
                      .copyWith(color: context.textPrimaryColor)),
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
              PopupMenuButton<String>(
                icon: Icon(Icons.sort_rounded,
                    color: context.textSecondaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: context.cardColor,
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (context) => [
                  _buildSortItem(
                      'name', context.l10n.nameAZ, Icons.sort_by_alpha_rounded),
                  _buildSortItem('balance', context.l10n.balanceHighLow,
                      Icons.account_balance_wallet_rounded),
                  _buildSortItem('recent', context.l10n.recentlyActive,
                      Icons.access_time_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Glass Search Bar
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
                  onChanged: (query) {
                    context.read<CustomerBloc>().add(SearchCustomers(query));
                  },
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchByNameOrPhone,
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: context.textSecondaryColor),
                    prefixIcon: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppGradients.primaryGradient.createShader(b),
                      child: const Icon(Icons.search_rounded, size: 22),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: context.textSecondaryColor, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<CustomerBloc>()
                                  .add(SearchCustomers(''));
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      bool isDark, int total, int owingCount, double pending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: AnimatedListItem(
              index: 0,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                gradient: AppGradients.primaryGradient,
                borderColor: Colors.white.withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const Spacer(),
                        Text('$total',
                            style: AppTextStyles.h2
                                .copyWith(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.l10n.totalCustomers,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9))),
                    Text(context.l10n.countWithPending(owingCount),
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedListItem(
              index: 1,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                gradient: AppGradients.dangerGradient,
                borderColor: Colors.white.withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 18),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CountingText(
                      value: pending,
                      prefix: '₹',
                      formatAsCompact: true,
                      style: AppTextStyles.h3.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    Text(context.l10n.totalPending,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark, List<CustomerModel> all) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _GlassFilterChip(
              label: context.l10n.filterAll,
              count: all.length,
              isSelected: _selectedFilter == 'all',
              onTap: () => setState(() => _selectedFilter = 'all')),
          _GlassFilterChip(
              label: context.l10n.filterOwing,
              count: all.where((c) => c.owesUs).length,
              isSelected: _selectedFilter == 'owing',
              color: AppColors.error,
              onTap: () => setState(() => _selectedFilter = 'owing')),
          _GlassFilterChip(
              label: context.l10n.weOwe,
              count: all.where((c) => c.currentBalance < 0).length,
              isSelected: _selectedFilter == 'owed',
              color: AppColors.success,
              onTap: () => setState(() => _selectedFilter = 'owed')),
          _GlassFilterChip(
              label: context.l10n.filterSettled,
              count: all.where((c) => c.currentBalance == 0).length,
              isSelected: _selectedFilter == 'settled',
              color: AppColors.neonCyan,
              onTap: () => setState(() => _selectedFilter = 'settled')),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
      String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: _sortBy == value
                  ? AppColors.primaryLight
                  : context.textSecondaryColor),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: _sortBy == value
                    ? AppColors.primaryLight
                    : context.textPrimaryColor,
                fontWeight: _sortBy == value ? FontWeight.w600 : null,
              )),
          if (_sortBy == value) ...[
            const Spacer(),
            const Icon(Icons.check_rounded,
                size: 18, color: AppColors.primaryLight)
          ],
        ],
      ),
    );
  }

  void _showQuickTransactionSheet(CustomerModel customer) {
    final amountController = TextEditingController();
    bool isCredit = true;

    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(customer.name[0].toUpperCase(),
                            style: AppTextStyles.h4
                                .copyWith(color: Colors.white))),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name,
                          style: AppTextStyles.labelLarge.copyWith(
                              color: context.textPrimaryColor)),
                      Text(
                          context.l10n.balanceAmount(customer.currentBalance.abs().toStringAsFixed(0)),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: customer.currentBalance > 0
                                ? AppColors.error
                                : AppColors.success,
                          )),
                    ],
                  )),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded,
                          color: context.textSecondaryColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: context.glassColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      setModalState(() => isCredit = true);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient:
                            isCredit ? AppGradients.dangerGradient : null,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                color: isCredit
                                    ? Colors.white
                                    : context.textSecondaryColor,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(context.l10n.creditUdhar,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: isCredit
                                        ? Colors.white
                                        : context.textSecondaryColor)),
                          ]),
                    ),
                  )),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      setModalState(() => isCredit = false);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient:
                            !isCredit ? AppGradients.successGradient : null,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded,
                                color: !isCredit
                                    ? Colors.white
                                    : context.textSecondaryColor,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(context.l10n.payment,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: !isCredit
                                        ? Colors.white
                                        : context.textSecondaryColor)),
                          ]),
                    ),
                  )),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.h2
                    .copyWith(color: context.textPrimaryColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: AppTextStyles.h2
                      .copyWith(color: context.textPrimaryColor),
                  hintText: '0',
                  hintStyle: AppTextStyles.h2
                      .copyWith(color: context.textSecondaryColor),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [100, 500, 1000, 2000, 5000].map((amount) {
                  return SpringContainer(
                    onTap: () {
                      final current =
                          int.tryParse(amountController.text) ?? 0;
                      amountController.text = '${current + amount}';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.glassColor,
                        borderRadius:
                            BorderRadius.circular(AppRadius.circular),
                        border:
                            Border.all(color: context.glassBorderColor),
                      ),
                      child: Text('+₹$amount',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: context.textPrimaryColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              MorphingGradientButton(
                label: isCredit ? context.l10n.addCredit : context.l10n.recordPayment,
                icon: isCredit
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                gradient: isCredit
                    ? AppGradients.dangerGradient
                    : AppGradients.successGradient,
                width: double.infinity,
                onTap: () {
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    Navigator.pop(ctx);
                    // Dispatch real transaction via TransactionBloc
                    final txnBloc = context.read<TransactionBloc>();
                    if (isCredit) {
                      txnBloc.add(AddCredit(
                        customerId: customer.id,
                        amount: amount,
                        description: context.l10n.quickCreditDescription,
                      ));
                    } else {
                      txnBloc.add(AddPayment(
                        customerId: customer.id,
                        amount: amount,
                        description: context.l10n.quickPaymentDescription,
                      ));
                    }
                    // Refresh customer list
                    context.read<CustomerBloc>().add(RefreshCustomers());

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isCredit
                            ? context.l10n.creditAddedSnackbar(amount.toStringAsFixed(0), customer.name)
                            : context.l10n.paymentReceivedSnackbar(amount.toStringAsFixed(0), customer.name)),
                        backgroundColor:
                            isCredit ? AppColors.error : AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _callCustomer(CustomerModel customer) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.l10n.callingPhone(customer.phone)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
    );
  }

  void _messageCustomer(CustomerModel customer) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.l10n.openingWhatsApp(customer.name)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
    );
  }
}

// ═══════════════════════ Supporting Widgets ═══════════════════════

class _GlassFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _GlassFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
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
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [chipColor, chipColor.withValues(alpha: 0.8)])
                : null,
            color: isSelected ? null : context.glassColor,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.3)
                  : context.glassBorderColor,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: chipColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: -2),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.textSecondaryColor,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAddTransaction;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const _GlassCustomerCard({
    required this.customer,
    required this.isDark,
    required this.onTap,
    required this.onAddTransaction,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SpringContainer(
        onTap: onTap,
        child: GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  TrustScoreRing(
                    score: customer.trustScore.toDouble(),
                    size: 52,
                    strokeWidth: 3,
                    center: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primaryGradient,
                      ),
                      child: Center(
                          child: Text(
                        customer.name[0].toUpperCase(),
                        style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      )),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style: AppTextStyles.labelLarge.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.phone_rounded,
                              size: 12,
                              color: context.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(customer.phone,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: context.textSecondaryColor)),
                        ]),
                        if (customer.lastTransactionAt != null)
                          Text(
                              context.l10n.lastDate(_formatDate(customer.lastTransactionAt!)),
                              style: AppTextStyles.caption.copyWith(
                                  color: context.textSecondaryColor,
                                  fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer.currentBalance.abs().toStringAsFixed(0)}',
                        style: AppTextStyles.h4.copyWith(
                          color: customer.currentBalance > 0
                              ? AppColors.error
                              : customer.currentBalance < 0
                                  ? AppColors.success
                                  : context.textSecondaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GradientBadge(
                        label: customer.currentBalance > 0
                            ? context.l10n.owesYou
                            : customer.currentBalance < 0
                                ? context.l10n.youOweLabel
                                : context.l10n.settled,
                        gradient: customer.currentBalance > 0
                            ? AppGradients.dangerGradient
                            : customer.currentBalance < 0
                                ? AppGradients.successGradient
                                : const LinearGradient(colors: [
                                    AppColors.grey500,
                                    AppColors.grey400
                                  ]),
                        fontSize: 9,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _GlassActionBtn(
                      icon: Icons.add_circle_outline_rounded,
                      label: context.l10n.transaction,
                      gradient: AppGradients.primaryGradient,
                      onTap: onAddTransaction),
                  const SizedBox(width: AppSpacing.xs),
                  _GlassActionBtn(
                      icon: Icons.phone_rounded,
                      label: context.l10n.callCustomer,
                      gradient: AppGradients.successGradient,
                      onTap: onCall),
                  const SizedBox(width: AppSpacing.xs),
                  _GlassActionBtn(
                      icon: Icons.message_rounded,
                      label: context.l10n.whatsApp,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF25D366), Color(0xFF128C7E)]),
                      onTap: onMessage),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}

class _GlassActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GlassActionBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SpringContainer(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.glassColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: context.glassBorderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => gradient.createShader(b),
                child: Icon(icon, size: 14),
              ),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
