import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/presentation/bloc/customer_event.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

class AddTransactionPage extends StatefulWidget {
  final String? customerId;
  /// Initial transaction type: 'credit' or 'payment'
  final String? initialType;

  const AddTransactionPage({
    super.key, 
    this.customerId,
    this.initialType,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  /// true = payment (customer pays money), false = credit (customer takes goods)
  /// Note: Using clear naming to avoid confusion
  late bool _isPayment;
  String? _selectedCustomerId;
  bool _showCustomerSearch = false;
  int _paymentMode = 0; // 0=cash, 1=upi, 2=card, 3=other

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    
    // Set initial transaction type from parameter
    // Default to credit (customer takes goods) if not specified
    _isPayment = widget.initialType == 'payment';
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // If a customer was pre-selected, don't show search
    if (widget.customerId != null) {
      _showCustomerSearch = false;
    } else {
      _showCustomerSearch = true;
    }

    // Load customers from global BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(LoadCustomers());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  CustomerModel? _findCustomer(List<CustomerModel> customers) {
    if (_selectedCustomerId == null) return null;
    try {
      return customers.firstWhere((c) => c.id == _selectedCustomerId);
    } catch (_) {
      return null;
    }
  }

  void _onSave() {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectCustomer),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) return;

      HapticFeedback.mediumImpact();

      final desc = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (_isPayment) {
        // Customer is paying us (payment received) - balance decreases
        context.read<TransactionBloc>().add(AddPayment(
          customerId: _selectedCustomerId!,
          amount: amount,
          paymentMode: _paymentMode,
          description: desc,
        ));
      } else {
        // Customer takes goods on credit (udhar) - balance increases
        context.read<TransactionBloc>().add(AddCredit(
          customerId: _selectedCustomerId!,
          amount: amount,
          description: desc,
        ));
      }
    }
  }

  void _showSuccessAndPop(TransactionAdded state) {
    final amount = state.transaction.totalAmount.toStringAsFixed(0);
    final customerName = state.updatedCustomer?.name ?? context.l10n.customer;
    final isPayment = state.transaction.isDebit;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPayment
                          ? [AppColors.success, AppColors.success.withAlpha(178)]
                          : [AppColors.secondary, AppColors.secondaryLight],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isPayment ? AppColors.success : AppColors.secondary)
                            .withAlpha(76),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 40,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPayment ? context.l10n.paymentReceivedSuccess : context.l10n.creditRecordedSuccess,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${isPayment ? '+' : '-'}${AppConstants.currencySymbol}$amount',
                style: AppTextStyles.h2.copyWith(
                  color: isPayment ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPayment ? context.l10n.fromName(customerName) : context.l10n.toName(customerName),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              if (state.updatedCustomer != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.balanceAmount(state.updatedCustomer!.currentBalance.toStringAsFixed(0)),
                  style: AppTextStyles.caption.copyWith(
                    color: state.updatedCustomer!.owesUs
                        ? AppColors.error
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: context.l10n.done,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionAdded) {
            _showSuccessAndPop(state);
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(context.l10n.newTransaction),
            elevation: 0,
          ),
          body: FadeTransition(
            opacity: _animController,
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, customerState) {
                final customers = customerState is CustomerLoaded
                    ? customerState.customers
                    : <CustomerModel>[];
                final selectedCustomer = _findCustomer(customers);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight -
                              AppSpacing.lg * 2,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Transaction Type Toggle
                              AnimatedListItem(
                                index: 0,
                                child: _buildTransactionTypeToggle(isDark),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Customer Selection
                              AnimatedListItem(
                                index: 1,
                                child: _buildCustomerSection(
                                    isDark, customers, selectedCustomer),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Amount Section
                              AnimatedListItem(
                                index: 2,
                                child: _buildAmountSection(
                                    isDark, selectedCustomer),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Payment Mode (only for payments)
                              if (_isPayment) ...[
                                AnimatedListItem(
                                  index: 3,
                                  child: _buildPaymentModeSection(isDark),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],

                              // Description
                              AnimatedListItem(
                                index: 4,
                                child: _buildSectionCard(
                                  context.l10n.detailsSection,
                                  Icons.notes,
                                  AppColors.grey600,
                                  isDark,
                                  children: [
                                    CustomTextField(
                                      controller: _descriptionController,
                                      label: context.l10n.descriptionOptional,
                                      hint: _isPayment
                                          ? context.l10n.paymentViaCashHint
                                          : context.l10n.groceryItemsHint,
                                      prefixIcon: Icons.edit_note,
                                      maxLines: 2,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Save Button
                              AnimatedListItem(
                                index: 5,
                                child: BlocBuilder<TransactionBloc,
                                    TransactionState>(
                                  builder: (context, txnState) {
                                    final isLoading =
                                        txnState is TransactionLoading;
                                    return CustomButton(
                                      text: _isPayment
                                          ? context.l10n.recordPaymentPlus
                                          : context.l10n.recordPurchaseMinus,
                                      onPressed: _onSave,
                                      isLoading: isLoading,
                                      backgroundColor: _isPayment
                                          ? AppColors.success
                                          : AppColors.error,
                                      icon: _isPayment
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.navClearance),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
    );
  }

  Widget _buildTransactionTypeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              isPaymentType: false, // Credit - customer takes goods
              label: context.l10n.newPurchase,
              subtitle: context.l10n.customerBuysOnCredit,
              icon: Icons.arrow_upward,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              isPaymentType: true, // Payment - customer pays money
              label: context.l10n.paymentReceived,
              subtitle: context.l10n.customerPaysYou,
              icon: Icons.arrow_downward,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required bool isPaymentType,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _isPayment == isPaymentType;
    return GestureDetector(
      onTap: () {
        setState(() => _isPayment = isPaymentType);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(38),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isSelected ? color : AppColors.grey400).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : AppColors.grey400,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? color : AppColors.grey500,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(
    bool isDark,
    List<CustomerModel> customers,
    CustomerModel? selectedCustomer,
  ) {
    return _buildSectionCard(
      context.l10n.customer,
      Icons.person,
      AppColors.primary,
      isDark,
      children: [
        if (selectedCustomer != null && !_showCustomerSearch) ...[
          // Selected customer card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withAlpha(51)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withAlpha(38),
                  child: Text(
                    selectedCustomer.name.isNotEmpty
                        ? selectedCustomer.name.substring(0, 1).toUpperCase()
                        : '?',
                    style:
                        AppTextStyles.h4.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCustomer.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10n.balanceAmount(selectedCustomer.currentBalance.toStringAsFixed(0)),
                        style: AppTextStyles.caption.copyWith(
                          color: selectedCustomer.owesUs
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.swap_horiz, color: AppColors.primary),
                  onPressed: () {
                    setState(() => _showCustomerSearch = true);
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          // Customer search
          CustomTextField(
            controller: _searchController,
            hint: context.l10n.searchByNameOrPhone,
            prefixIcon: Icons.search,
            onChanged: (query) {
              if (query.isEmpty) {
                context.read<CustomerBloc>().add(LoadCustomers());
              } else {
                context.read<CustomerBloc>().add(SearchCustomers(query));
              }
            },
          ),
          const SizedBox(height: 8),
          if (customers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 40, color: AppColors.grey400),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noCustomersFound,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.addCustomersFirst,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final isSelected = _selectedCustomerId == customer.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCustomerId = customer.id;
                        _showCustomerSearch = false;
                        _searchController.clear();
                      });
                      context.read<CustomerBloc>().add(LoadCustomers());
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey200,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withAlpha(25),
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style:
                                      AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  customer.phone,
                                  style:
                                      AppTextStyles.caption.copyWith(
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${AppConstants.currencySymbol}${customer.currentBalance.toStringAsFixed(0)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: customer.owesUs
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAmountSection(bool isDark, CustomerModel? selectedCustomer) {
    final color = _isPayment ? AppColors.success : AppColors.error;

    return _buildSectionCard(
      context.l10n.amount,
      Icons.currency_rupee,
      color,
      isDark,
      children: [
        // Big amount input
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withAlpha(38)),
          ),
          child: Column(
            children: [
              Text(
                _isPayment ? context.l10n.paymentAmountLabel : context.l10n.purchaseAmountLabel,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.currencySymbol,
                    style: AppTextStyles.h2.copyWith(color: color),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) => Validators.validateAmount(v, l10n: context.l10n),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick amount buttons
        Text(context.l10n.quickAmount, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [50, 100, 200, 500, 1000, 2000, 5000].map((amt) {
            return AnimatedScaleOnTap(
              onTap: () {
                setState(() {
                  _amountController.text = amt.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(51)),
                ),
                child: Text(
                  '${AppConstants.currencySymbol}$amt',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Balance info if customer selected
        if (selectedCustomer != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.currentBalanceAmount(selectedCustomer.currentBalance.toStringAsFixed(0)),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentModeSection(bool isDark) {
    final modes = [
      (0, Icons.payments, context.l10n.cash),
      (1, Icons.phone_android, context.l10n.upi),
      (2, Icons.account_balance, context.l10n.bank),
      (3, Icons.receipt, context.l10n.otherPayment),
    ];

    return _buildSectionCard(
      context.l10n.paymentMode,
      Icons.payment,
      AppColors.info,
      isDark,
      children: [
        Row(
          children: modes.map((mode) {
            final isSelected = _paymentMode == mode.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedScaleOnTap(
                  onTap: () {
                    setState(() => _paymentMode = mode.$1);
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.$2,
                          size: 22,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode.$3,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.grey600,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(isDark ? 51 : 25),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
