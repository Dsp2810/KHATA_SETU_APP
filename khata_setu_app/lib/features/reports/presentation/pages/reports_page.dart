import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/data/models/transaction_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/ledger_rules.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/presentation/bloc/customer_event.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../../../ledger/presentation/bloc/transaction_bloc.dart';
import '../../../ledger/presentation/bloc/transaction_event.dart';
import '../../../ledger/presentation/bloc/transaction_state.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  ReportType _selectedReportType = ReportType.daily;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedCustomer; // stores customer ID
  String? _selectedCustomerName; // stores customer name for PDF
  bool _isGenerating = false;

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(LoadCustomers());
      context.read<TransactionBloc>().add(LoadAllTransactions());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      // Get real data from BLoCs
      final txnState = context.read<TransactionBloc>().state;
      final custState = context.read<CustomerBloc>().state;

      List<TransactionModel> allTxns = [];
      List<CustomerModel> customers = [];

      if (txnState is AllTransactionsLoaded) {
        allTxns = txnState.transactions;
      }
      if (custState is CustomerLoaded) {
        customers = custState.customers;
      }

      // Build customer name map
      final custMap = <String, String>{};
      for (final c in customers) {
        custMap[c.id] = c.name;
      }

      // Filter transactions by date range
      final filtered = allTxns.where((t) {
        final d = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
        final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
        final end = DateTime(_endDate.year, _endDate.month, _endDate.day).add(const Duration(days: 1));
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();

      // If customer statement, filter by selected customer ID
      final forReport = _selectedCustomer != null
          ? filtered.where((t) => t.customerId == _selectedCustomer).toList()
          : filtered;

      // Build ReportTransaction list
      final transactions = forReport.map((t) => ReportTransaction(
        id: t.id,
        customerName: custMap[t.customerId] ?? 'Unknown',
        type: t.transactionType.name, // 'credit' or 'payment'
        amount: t.totalAmount,
        date: t.timestamp,
        description: t.description ?? (t.items.isNotEmpty ? t.items.map((i) => i.name).join(', ') : t.typeLabel),
        items: t.items.map((i) => ReportItem(
          name: i.name,
          quantity: i.quantity.toInt(),
          price: i.price,
          unit: i.unit ?? 'pcs',
        )).toList(),
      )).toList();

      // Compute summary
      final totalCredit = forReport
          .where((t) => t.transactionType == TransactionType.credit)
          .fold<double>(0, (s, t) => s + t.totalAmount);
      final totalPayment = forReport
          .where((t) => t.transactionType == TransactionType.payment)
          .fold<double>(0, (s, t) => s + t.totalAmount);
      final uniqueCustomerIds = forReport.map((t) => t.customerId).toSet();

      // Category breakdown from items or description
      final catBreakdown = <String, double>{};
      for (final t in forReport.where((t) => t.transactionType == TransactionType.credit)) {
        final cat = t.items.isNotEmpty ? t.items.first.name : (t.description ?? 'Other');
        catBreakdown[cat] = (catBreakdown[cat] ?? 0) + t.totalAmount;
      }

      final summary = ReportSummary(
        totalCredit: totalCredit,
        totalDebit: totalPayment,
        netBalance: totalCredit - totalPayment,
        transactionCount: transactions.length,
        customerCount: uniqueCustomerIds.length,
        categoryBreakdown: catBreakdown,
      );

      // Build a file name for the report
      final reportTypeName = _selectedReportType.name;
      final dateStr = DateFormat('yyyyMMdd').format(_startDate);
      final fileName = 'KhataSetu_${reportTypeName}_report_$dateStr.pdf';

      final secureStorage = getIt<SecureStorageService>();
      final shopName = await secureStorage.read('shop_name') ?? AppConstants.appName;

      final bytes = await PdfReportService.generateReport(
        type: _selectedReportType,
        shopName: shopName,
        startDate: _startDate,
        endDate: _endDate,
        transactions: transactions,
        summary: summary,
        l10n: context.l10n,
        customerName: _selectedCustomerName,
        locale: Localizations.localeOf(context).languageCode,
      );

      if (mounted) {
        _showPdfActionsSheet(bytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportError(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// Show bottom sheet with Print / Share / Save options after PDF is generated
  void _showPdfActionsSheet(Uint8List bytes, String fileName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.reportGeneratedTitle,
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.chooseAction,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                ),
                const SizedBox(height: 24),

                // Preview / Print
                _buildActionTile(
                  icon: Icons.print_rounded,
                  color: AppColors.primary,
                  title: context.l10n.previewAndPrint,
                  subtitle: context.l10n.previewAndPrintSubtitle,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await PdfReportService.printReport(bytes);
                  },
                ),
                const SizedBox(height: 12),

                // Share
                _buildActionTile(
                  icon: Icons.share_rounded,
                  color: AppColors.info,
                  title: context.l10n.sharePdf,
                  subtitle: context.l10n.sharePdfSubtitle,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await PdfReportService.shareReport(bytes, fileName, l10n: context.l10n);
                  },
                ),
                const SizedBox(height: 12),

                // Save to device
                _buildActionTile(
                  icon: Icons.save_alt_rounded,
                  color: AppColors.success,
                  title: context.l10n.saveToDevice,
                  subtitle: context.l10n.saveToDeviceSubtitle,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final file = await PdfReportService.saveToFile(bytes, fileName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.white),
                              const SizedBox(width: 12),
                              Expanded(child: Text(context.l10n.savedTo(file.path))),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey200),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.reportsTitle),
        backgroundColor: context.cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navClearance,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            AnimatedListItem(
              index: 0,
              child: _buildReportTypeSection(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date Range Selection
            AnimatedListItem(
              index: 1,
              child: _buildDateRangeSection(isDark),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Customer Selection (for customer statement)
            if (_selectedReportType == ReportType.customerStatement)
              AnimatedListItem(
                index: 2,
                child: _buildCustomerSelection(isDark),
              ),
            if (_selectedReportType == ReportType.customerStatement)
              const SizedBox(height: AppSpacing.lg),

            // Quick Report Cards
            AnimatedListItem(
              index: 3,
              child: _buildQuickReportsSection(isDark),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Generate Button
            AnimatedListItem(
              index: 4,
              child: _buildGenerateButton(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent Reports
            AnimatedListItem(
              index: 5,
              child: _buildRecentReportsSection(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection(bool isDark) {
    final reportTypes = [
      {'type': ReportType.daily, 'label': context.l10n.daily, 'icon': Icons.today},
      {'type': ReportType.weekly, 'label': context.l10n.weekly, 'icon': Icons.view_week},
      {'type': ReportType.monthly, 'label': context.l10n.monthly, 'icon': Icons.calendar_month},
      {'type': ReportType.yearly, 'label': context.l10n.yearly, 'icon': Icons.calendar_today},
      {'type': ReportType.customerStatement, 'label': context.l10n.customer, 'icon': Icons.person},
      {'type': ReportType.custom, 'label': context.l10n.customLabel, 'icon': Icons.tune},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reportTypeLabel,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: reportTypes.map((rt) {
            final isSelected = _selectedReportType == rt['type'];
            return AnimatedScaleOnTap(
              onTap: () {
                setState(() => _selectedReportType = rt['type'] as ReportType);
                // Auto-set date range based on type
                _autoSetDateRange(rt['type'] as ReportType);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: !isSelected
                      ? context.cardColor
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.grey300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rt['icon'] as IconData,
                      size: 18,
                      color: isSelected ? AppColors.white : AppColors.grey600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rt['label'] as String,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected ? AppColors.white : AppColors.grey700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getCustomerDropdownItems() {
    final state = context.read<CustomerBloc>().state;
    if (state is CustomerLoaded) {
      return state.customers.map((c) {
        return DropdownMenuItem(
          value: c.id,
          child: Text(c.name),
        );
      }).toList();
    }
    return [];
  }

  void _autoSetDateRange(ReportType type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case ReportType.daily:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate;
          break;
        case ReportType.weekly:
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case ReportType.monthly:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case ReportType.yearly:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        default:
          break;
      }
    });
  }

  Widget _buildDateRangeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.date_range, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.dateRange,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedScaleOnTap(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.grey800
                    : AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.fromLabel,
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(_startDate),
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_forward, color: AppColors.white, size: 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.toLabel,
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(_endDate),
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildCustomerSelection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.selectCustomer,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: _selectedCustomer,
            decoration: InputDecoration(
              hintText: context.l10n.selectCustomerHint,
              filled: true,
              fillColor: context.inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _getCustomerDropdownItems(),
            onChanged: (val) {
              final customers = (context.read<CustomerBloc>().state as CustomerLoaded).customers;
              final selected = customers.firstWhere((c) => c.id == val);
              setState(() {
                _selectedCustomer = val;
                _selectedCustomerName = selected.name;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReportsSection(bool isDark) {
    // Get real data from BLoCs
    final custState = context.read<CustomerBloc>().state;
    final txnState = context.read<TransactionBloc>().state;

    List<CustomerModel> customers = [];
    List<TransactionModel> allTxns = [];

    if (custState is CustomerLoaded) customers = custState.customers;
    if (txnState is AllTransactionsLoaded) allTxns = txnState.transactions;

    // Today's summary
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTxns = allTxns.where((t) => t.timestamp.isAfter(todayStart)).toList();
    final todayTotal = todayTxns.fold<double>(0, (s, t) => s + t.totalAmount);

    // This month
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTxns = allTxns.where((t) => t.timestamp.isAfter(monthStart)).toList();
    final monthTotal = monthTxns.fold<double>(0, (s, t) => s + t.totalAmount);

    // Outstanding
    final totalOutstanding = customers.fold<double>(
        0, (s, c) => c.currentBalance > 0 ? s + c.currentBalance : s);
    final debtorCount = customers.where((c) => c.owesUs).length;

    String formatCompact(double v) {
      if (v >= 100000) return '${AppConstants.currencySymbol}${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) return '${AppConstants.currencySymbol}${(v / 1000).toStringAsFixed(1)}K';
      return '${AppConstants.currencySymbol}${v.toStringAsFixed(0)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.quickReports,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickReportCard(
                context.l10n.todaysSummaryLabel,
                Icons.today,
                AppColors.primary,
                formatCompact(todayTotal),
                context.l10n.transactionCount(todayTxns.length),
                isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickReportCard(
                context.l10n.thisMonth,
                Icons.calendar_month,
                AppColors.success,
                formatCompact(monthTotal),
                context.l10n.transactionCount(monthTxns.length),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickReportCard(
                context.l10n.outstanding,
                Icons.account_balance_wallet,
                AppColors.warning,
                formatCompact(totalOutstanding),
                context.l10n.pendingDues,
                isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickReportCard(
                context.l10n.topCustomersLabel,
                Icons.star,
                AppColors.secondary,
                '$debtorCount',
                context.l10n.activeDebtors,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReportCard(
    String title,
    IconData icon,
    Color color,
    String value,
    String subtitle,
    bool isDark,
  ) {
    return AnimatedScaleOnTap(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return AnimatedScaleOnTap(
      onTap: _isGenerating ? null : _generateReport,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isGenerating ? null : _generateReport,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Center(
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.white),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            context.l10n.generateReportButton,
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildRecentReportsSection(bool isDark) {
    // Show recent transaction activity summary (no report history storage yet)
    final txnState = context.read<TransactionBloc>().state;
    final custState = context.read<CustomerBloc>().state;

    List<TransactionModel> recentTxns = [];
    Map<String, String> custMap = {};

    if (txnState is AllTransactionsLoaded) {
      recentTxns = txnState.transactions.take(5).toList();
    }
    if (custState is CustomerLoaded) {
      for (final c in custState.customers) {
        custMap[c.id] = c.name;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.recentActivity,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recentTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  context.l10n.noTransactionsReportHint,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...recentTxns.map((txn) {
              final custName = custMap[txn.customerId] ?? 'Unknown';
              final isCredit = txn.isCredit;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCredit ? AppColors.error : AppColors.success).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isCredit ? AppColors.error : AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            custName,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _dateFormat.format(txn.timestamp),
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}${AppConstants.currencySymbol}${txn.totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCredit ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
