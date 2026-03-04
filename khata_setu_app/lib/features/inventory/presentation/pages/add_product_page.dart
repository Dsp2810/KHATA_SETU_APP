import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Grocery';
  String _selectedUnit = 'pcs';
  bool _isLoading = false;
  bool _trackInventory = true;

  late AnimationController _animController;

  final Map<String, IconData> _categoryIcons = {
    'Grocery': Icons.shopping_basket,
    'Stationary': Icons.edit,
    'Electronics': Icons.devices,
    'Household': Icons.home,
    'Personal Care': Icons.spa,
    'Beverages': Icons.local_drink,
    'Snacks': Icons.fastfood,
    'Other': Icons.category,
  };

  final List<String> _units = [
    'pcs', 'kg', 'g', 'L', 'ml', 'dozen', 'packet', 'box', 'bundle',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double get _margin {
    final buy = double.tryParse(_buyPriceController.text) ?? 0;
    final sell = double.tryParse(_sellPriceController.text) ?? 0;
    if (buy <= 0) return 0;
    return ((sell - buy) / buy) * 100;
  }

  double get _profit {
    final buy = double.tryParse(_buyPriceController.text) ?? 0;
    final sell = double.tryParse(_sellPriceController.text) ?? 0;
    return sell - buy;
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      context.read<InventoryBloc>().add(AddProduct(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        unit: _selectedUnit,
        purchasePrice: double.tryParse(_buyPriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellPriceController.text) ?? 0,
        currentStock: double.tryParse(_stockController.text) ?? 0,
        minStockLevel: double.tryParse(_minStockController.text) ?? 5,
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      ));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.productAddedTitle,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                context.l10n.productAddedToInventory(_nameController.text),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.addMore,
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetForm();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.done,
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.pop();
                      },
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

  void _resetForm() {
    _nameController.clear();
    _skuController.clear();
    _buyPriceController.clear();
    _sellPriceController.clear();
    _stockController.clear();
    _minStockController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = 'Grocery';
      _selectedUnit = 'pcs';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryActionSuccess) {
          setState(() => _isLoading = false);
          _showSuccessDialog();
        } else if (state is InventoryError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addProduct),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _onSave,
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.l10n.save),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image Placeholder
                AnimatedListItem(
                  index: 0,
                  child: _buildImagePlaceholder(isDark),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Basic Info
                AnimatedListItem(
                  index: 1,
                  child: _buildSectionCard(
                    context.l10n.basicInformation,
                    Icons.info_outline,
                    AppColors.primary,
                    isDark,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: context.l10n.productNameRequired,
                        hint: context.l10n.productNameHint,
                        prefixIcon: Icons.inventory_2_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => Validators.validateRequired(
                          value,
                          fieldName: context.l10n.productName,
                          l10n: context.l10n,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _skuController,
                        label: context.l10n.sku,
                        hint: context.l10n.scanOrEnterCode,
                        prefixIcon: Icons.qr_code_2,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _descriptionController,
                        label: context.l10n.descriptionOptional,
                        hint: context.l10n.briefDescription,
                        prefixIcon: Icons.description_outlined,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Category Selection
                AnimatedListItem(
                  index: 2,
                  child: _buildCategorySection(isDark),
                ),
                const SizedBox(height: AppSpacing.md),

                // Pricing
                AnimatedListItem(
                  index: 3,
                  child: _buildPricingSection(isDark),
                ),
                const SizedBox(height: AppSpacing.md),

                // Stock Management
                AnimatedListItem(
                  index: 4,
                  child: _buildStockSection(isDark),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Button
                AnimatedListItem(
                  index: 5,
                  child: CustomButton(
                    text: context.l10n.addProduct,
                    onPressed: _onSave,
                    isLoading: _isLoading,
                    icon: Icons.add_box,
                  ),
                ),
                const SizedBox(height: AppSpacing.navClearance),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return AnimatedScaleOnTap(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cameraGalleryComingSoon)),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.addProductImage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.tapToCaptureOrSelect,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(bool isDark) {
    return _buildSectionCard(
      context.l10n.categoryAndUnit,
      Icons.category,
      AppColors.secondary,
      isDark,
      children: [
        Text(context.l10n.category, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryIcons.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return AnimatedScaleOnTap(
              onTap: () {
                setState(() => _selectedCategory = entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.secondary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.grey300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value,
                      size: 16,
                      color: isSelected ? AppColors.white : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.white : AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.unit, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _units.map((unit) {
            final isSelected = _selectedUnit == unit;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedUnit = unit);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                  ),
                ),
                child: Text(
                  unit,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isDark) {
    return _buildSectionCard(
      context.l10n.pricingSection,
      Icons.currency_rupee,
      AppColors.success,
      isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _buyPriceController,
                label: context.l10n.buyPriceRequired,
                hint: context.l10n.costLabel,
                prefixIcon: Icons.arrow_downward,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateAmount(v, l10n: context.l10n),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _sellPriceController,
                label: context.l10n.sellPriceRequired,
                hint: context.l10n.mrpLabel,
                prefixIcon: Icons.arrow_upward,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateAmount(v, l10n: context.l10n),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),

        // Margin calculator
        if (_buyPriceController.text.isNotEmpty &&
            _sellPriceController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (_profit >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.05),
                    (_profit >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (_profit >= 0 ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _profit >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 18,
                            color: _profit >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.profit,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.currencySymbol}${_profit.toStringAsFixed(1)}',
                        style: AppTextStyles.h4.copyWith(
                          color: _profit >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.grey300,
                  ),
                  Column(
                    children: [
                      Text(
                        context.l10n.marginLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_margin.toStringAsFixed(1)}%',
                        style: AppTextStyles.h4.copyWith(
                          color: _margin >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockSection(bool isDark) {
    return _buildSectionCard(
      context.l10n.stockManagement,
      Icons.inventory,
      AppColors.info,
      isDark,
      children: [
        // Track inventory toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.trackInventory,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              )),
          subtitle: Text(
            context.l10n.enableStockAlerts,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
          ),
          value: _trackInventory,
          activeThumbColor: AppColors.primary,
          onChanged: (val) => setState(() => _trackInventory = val),
        ),

        if (_trackInventory) ...[
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _stockController,
                  label: context.l10n.currentStockRequired,
                  hint: context.l10n.qtyLabel,
                  prefixIcon: Icons.inventory_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateQuantity(v, l10n: context.l10n),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _minStockController,
                  label: context.l10n.minStockAlert,
                  hint: context.l10n.lowAlertHint,
                  prefixIcon: Icons.warning_amber_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick stock buttons
          Row(
            children: [
              Text(context.l10n.quickSetPrefix, style: AppTextStyles.labelMedium),
              const SizedBox(width: 8),
              ...[10, 25, 50, 100].map((qty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _stockController.text = qty.toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$qty',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
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
