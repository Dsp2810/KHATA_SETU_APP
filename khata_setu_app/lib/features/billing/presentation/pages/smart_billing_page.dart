import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/data/repositories/product_repository.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/presentation/bloc/customer_event.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../../../ledger/presentation/bloc/transaction_bloc.dart';
import '../../../ledger/presentation/bloc/transaction_event.dart';
import '../../../../core/data/models/transaction_model.dart';

/// Item model for billing
class BillItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final IconData icon;
  int quantity;

  BillItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.unit = 'pcs',
    this.icon = Icons.inventory_2,
    this.quantity = 0,
  });

  double get total => price * quantity;

  BillItem copyWith({int? quantity}) {
    return BillItem(
      id: id,
      name: name,
      category: category,
      price: price,
      unit: unit,
      icon: icon,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Customer model for billing
class BillCustomer {
  final String id;
  final String name;
  final String phone;
  final double currentBalance;
  final String? avatar;

  BillCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.currentBalance = 0,
    this.avatar,
  });
}

class SmartBillingPage extends StatefulWidget {
  const SmartBillingPage({super.key});

  @override
  State<SmartBillingPage> createState() => _SmartBillingPageState();
}

class _SmartBillingPageState extends State<SmartBillingPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _cartAnimController;
  late Animation<double> _cartAnimation;

  BillCustomer? _selectedCustomer;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isProcessing = false;

  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  // Real customers from BLoC
  List<BillCustomer> _customers = [];

  List<String> get _categories {
    final cats = <String>{'All'};
    for (final item in _items) {
      cats.add(item.category);
    }
    return cats.toList();
  }

  late List<BillItem> _items;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _cartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cartAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _cartAnimController, curve: Curves.elasticOut),
    );

    _initItems();

    // Load customers from global BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(LoadCustomers());
      _loadCustomersFromBloc();
    });
  }

  void _loadCustomersFromBloc() {
    final state = context.read<CustomerBloc>().state;
    if (state is CustomerLoaded) {
      setState(() {
        _customers = state.customers.map((c) => BillCustomer(
          id: c.id,
          name: c.name,
          phone: c.phone,
          currentBalance: c.currentBalance,
          avatar: c.avatar,
        )).toList();
      });
    } else {
      // Retry after a brief delay if not yet loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadCustomersFromBloc();
      });
    }
  }

  void _initItems() {
    // Load products from repository
    try {
      final repo = getIt<ProductRepository>();
      final products = repo.getAllProducts();
      _items = products.map((p) => BillItem(
        id: p.id,
        name: p.name,
        category: p.category,
        price: p.sellingPrice,
        unit: p.unit,
        icon: _iconForCategory(p.category),
      )).toList();
    } catch (_) {
      _items = [];
    }

    // If no products in repo, show empty
    if (_items.isEmpty) {
      _items = [];
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
      case 'kirana':
        return Icons.shopping_basket;
      case 'dairy':
        return Icons.water_drop;
      case 'snacks':
        return Icons.fastfood;
      case 'beverages':
        return Icons.local_drink;
      case 'personal care':
        return Icons.spa;
      case 'stationery':
        return Icons.edit;
      case 'electronics':
        return Icons.devices;
      case 'household':
        return Icons.home;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cartAnimController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<BillItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<BillItem> get _cartItems => _items.where((item) => item.quantity > 0).toList();

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  int get _totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  String get _billDescription {
    if (_cartItems.isEmpty) return '';
    final customerName = _selectedCustomer?.name.split(' ').first ?? 'Customer';
    final itemDescriptions = _cartItems
        .map((item) => '${item.quantity} ${item.name}')
        .join(', ');
    return '$customerName has taken $itemDescriptions';
  }

  void _addToCart(BillItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    });
    _cartAnimController.forward().then((_) => _cartAnimController.reverse());
  }

  void _removeFromCart(BillItem item) {
    if (item.quantity > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      });
    }
  }

  Future<void> _processBill() async {
    if (_selectedCustomer == null) {
      _showErrorSnackBar(context.l10n.pleaseSelectCustomerFirst);
      return;
    }
    if (_cartItems.isEmpty) {
      _showErrorSnackBar(context.l10n.pleaseAddItemsToBill);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Generate bill PDF
      final items = _cartItems.map((item) => ReportItem(
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        unit: item.unit,
      )).toList();

      // Get shop info from secure storage
      final secureStorage = getIt<SecureStorageService>();
      final shopName = await secureStorage.read('shop_name') ?? 'My Shop';
      final shopPhone = await secureStorage.read('user_phone') ?? '';

      final bytes = await PdfReportService.generateBill(
        shopName: shopName,
        shopAddress: '',
        shopPhone: shopPhone,
        customerName: _selectedCustomer!.name,
        customerPhone: _selectedCustomer!.phone,
        billNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        date: DateTime.now(),
        items: items,
        l10n: context.l10n,
        previousBalance: _selectedCustomer!.currentBalance,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Show success dialog
      if (mounted) {
        // Record bill as a credit (udhar) transaction in the ledger
        final transactionItems = _cartItems.map((item) => TransactionItem(
          name: item.name,
          price: item.price,
          quantity: item.quantity.toDouble(),
        )).toList();

        context.read<TransactionBloc>().add(AddCredit(
          customerId: _selectedCustomer!.id,
          amount: _subtotal,
          items: transactionItems,
          description: 'Bill #INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        ));

        // Reload customers to reflect updated balance
        context.read<CustomerBloc>().add(LoadCustomers());

        _showSuccessDialog(bytes);
      }
    } catch (e) {
      _showErrorSnackBar(context.l10n.errorGeneratingBill(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog(List<int> pdfBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, Color(0xFF66BB6A)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, size: 40, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.billCreated,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _billDescription,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${context.l10n.total}: ${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await PdfReportService.shareReport(
                          Uint8List.fromList(pdfBytes),
                          'bill_${DateTime.now().millisecondsSinceEpoch}.pdf',
                          l10n: context.l10n,
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: Text(context.l10n.share),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PdfReportService.printReport(Uint8List.fromList(pdfBytes));
                        if (mounted) Navigator.pop(ctx);
                        _resetBill();
                      },
                      icon: const Icon(Icons.print),
                      label: Text(context.l10n.print),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetBill();
                },
                child: Text(context.l10n.newBill),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetBill() {
    setState(() {
      _selectedCustomer = null;
      _notesController.clear();
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(quantity: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Customer Selection
          AnimatedListItem(
            index: 0,
            child: _buildCustomerSection(isDark),
          ),

          // Category Tabs
          AnimatedListItem(
            index: 1,
            child: _buildCategoryTabs(isDark),
          ),

          // Search Bar
          AnimatedListItem(
            index: 2,
            child: _buildSearchBar(isDark),
          ),

          // Items Grid
          Expanded(
            child: Stack(
              children: [
                _buildItemsGrid(isDark),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildCartSummary(isDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(context.l10n.smartBillingTitle),
      backgroundColor: context.cardColor,
      elevation: 0,
      actions: [
        if (_cartItems.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.l10n.clearBillTitle),
                  content: Text(context.l10n.clearBillMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetBill();
                      },
                      child: Text(context.l10n.clear, style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ScaleTransition(
          scale: _cartAnimation,
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _showCartSheet,
              ),
              if (_totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _totalItems.toString(),
                      style: const TextStyle(
                        color: AppColors.white,
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
      ],
    );
  }

  Widget _buildCustomerSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: context.cardColor,
      child: AnimatedScaleOnTap(
        onTap: _showCustomerPicker,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: _selectedCustomer != null
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primaryLight.withOpacity(0.05),
                    ],
                  )
                : null,
            color: _selectedCustomer == null
                ? context.inputFillColor
                : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _selectedCustomer != null
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.grey300,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: _selectedCustomer != null
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: _selectedCustomer == null ? AppColors.grey300 : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _selectedCustomer != null
                      ? Text(
                          _selectedCustomer!.name[0].toUpperCase(),
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(Icons.person_add, color: AppColors.grey600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCustomer?.name ?? context.l10n.selectCustomer,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _selectedCustomer != null
                            ? null
                            : AppColors.grey600,
                      ),
                    ),
                    if (_selectedCustomer != null)
                      Row(
                        children: [
                          Text(
                            _selectedCustomer!.phone,
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedCustomer!.currentBalance > 0
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${AppConstants.currencySymbol}${_selectedCustomer!.currentBalance.abs().toStringAsFixed(0)} ${_selectedCustomer!.currentBalance > 0 ? context.l10n.due : context.l10n.advShort}',
                              style: AppTextStyles.caption.copyWith(
                                color: _selectedCustomer!.currentBalance > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.grey500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  context.l10n.selectCustomer,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _customers.length,
                  itemBuilder: (_, index) {
                    final customer = _customers[index];
                    final isSelected = _selectedCustomer?.id == customer.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.grey200,
                        child: Text(
                          customer.name[0],
                          style: TextStyle(
                            color: isSelected ? AppColors.white : AppColors.grey700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : Text(
                              '${AppConstants.currencySymbol}${customer.currentBalance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: customer.currentBalance > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      onTap: () {
                        setState(() => _selectedCustomer = customer);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    return Container(
      height: 50,
      color: context.cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedScaleOnTap(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: !isSelected ? AppColors.grey100 : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: context.l10n.searchBilling,
          prefixIcon: const Icon(Icons.search, color: AppColors.grey500),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: context.inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(bool isDark) {
    final items = _filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              context.l10n.noItemsFound,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.navClearance + (_cartItems.isNotEmpty ? 80 : 0),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive.gridCrossAxisCount,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, isDark);
      },
    );
  }

  Widget _buildItemCard(BillItem item, bool isDark) {
    final hasQuantity = item.quantity > 0;

    return AnimatedScaleOnTap(
      onTap: () => _addToCart(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasQuantity ? AppColors.primary : AppColors.grey200,
            width: hasQuantity ? 2 : 1,
          ),
          boxShadow: [
            if (hasQuantity)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
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
                        child: Icon(item.icon, color: AppColors.primary, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        '${AppConstants.currencySymbol}${item.price.toStringAsFixed(0)}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/${item.unit}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),

            // Quantity badge
            if (hasQuantity)
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _removeFromCart(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 16, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bill description preview
            if (_billDescription.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _billDescription,
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.itemsCount(_totalItems),
                        style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                AnimatedScaleOnTap(
                  onTap: _isProcessing ? null : _processBill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt, color: AppColors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.createBill,
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.cartWithCount(_totalItems),
                        style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${_subtotal.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 64, color: AppColors.grey400),
                              const SizedBox(height: 16),
                              Text(
                                context.l10n.yourCartIsEmpty,
                                style: AppTextStyles.bodyLarge
                                    .copyWith(color: AppColors.grey500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          itemCount: _cartItems.length,
                          itemBuilder: (_, index) {
                            final item = _cartItems[index];
                            return _buildCartItem(item, isDark);
                          },
                        ),
                ),
                if (_cartItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: context.l10n.addNotesOptional,
                        prefixIcon: const Icon(Icons.note_add_outlined),
                        filled: true,
                        fillColor: context.inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BillItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${AppConstants.currencySymbol}${item.price.toStringAsFixed(0)} × ${item.quantity}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
                onPressed: () {
                  _removeFromCart(item);
                  if (item.quantity == 1) Navigator.pop(context);
                },
              ),
              Text(
                item.quantity.toString(),
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: AppColors.white),
                ),
                onPressed: () => _addToCart(item),
              ),
            ],
          ),
          Text(
            '${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
