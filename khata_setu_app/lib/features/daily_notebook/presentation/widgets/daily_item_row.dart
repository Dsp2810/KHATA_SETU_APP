import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';

/// An animated editable item row for the daily note editor.
/// Supports autocomplete for product name, quantity ± buttons,
/// and swipe-to-delete.
class DailyItemRow extends StatefulWidget {
  final DailyItemModel item;
  final List<String> productNames;
  final ValueChanged<DailyItemModel> onUpdate;
  final VoidCallback onRemove;

  const DailyItemRow({
    super.key,
    required this.item,
    required this.productNames,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<DailyItemRow> createState() => _DailyItemRowState();
}

class _DailyItemRowState extends State<DailyItemRow>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.item.productName);
    _priceController = TextEditingController(
        text: widget.item.unitPrice > 0
            ? widget.item.unitPrice.toStringAsFixed(0)
            : '');
    _qtyController = TextEditingController(
        text: widget.item.quantity.toStringAsFixed(
            widget.item.quantity == widget.item.quantity.toInt()
                ? 0
                : 1));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _updateItem({
    String? productName,
    double? quantity,
    double? unitPrice,
    String? unit,
    int? timeLabel,
  }) {
    widget.onUpdate(widget.item.copyWith(
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      unit: unit,
      timeLabel: timeLabel,
    ));
  }

  void _incrementQuantity() {
    final newQty = widget.item.quantity + 1;
    _qtyController.text = newQty.toStringAsFixed(
        newQty == newQty.toInt() ? 0 : 1);
    _updateItem(quantity: newQty);
  }

  void _decrementQuantity() {
    if (widget.item.quantity <= 0.5) return;
    final newQty = widget.item.quantity - (widget.item.quantity >= 1 ? 1 : 0.5);
    _qtyController.text = newQty.toStringAsFixed(
        newQty == newQty.toInt() ? 0 : 1);
    _updateItem(quantity: newQty);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.totalPrice;

    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _slideAnim,
        child: Dismissible(
          key: Key(widget.item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onRemove(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.credit.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.delete_outline,
                color: AppColors.credit),
          ),
          child: SurfaceCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                // Row 1: Product name + remove button
                Row(
                  children: [
                    Expanded(
                      child: _buildAutocompleteField(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: widget.onRemove,
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: context.textTertiaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Row 2: Quantity controls + Price + Total
                Row(
                  children: [
                    // Quantity controls
                    _buildQuantityControls(context),
                    const SizedBox(width: AppSpacing.sm),
                    // × symbol
                    Text('×',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: context.textTertiaryColor)),
                    const SizedBox(width: AppSpacing.sm),
                    // Unit price input
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '₹0',
                          hintStyle: AppTextStyles.bodySmall.copyWith(
                              color: context.textTertiaryColor),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                                color: context.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                                color: context.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          final price = double.tryParse(val) ?? 0;
                          _updateItem(unitPrice: price);
                        },
                      ),
                    ),
                    const Spacer(),
                    // Total
                    Text(
                      '${AppConstants.currencySymbol}${total.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
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

  Widget _buildAutocompleteField(BuildContext context) {
    return Autocomplete<String>(
      initialValue: _nameController.value,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final query = textEditingValue.text.toLowerCase();
        return widget.productNames
            .where((p) => p.toLowerCase().contains(query))
            .take(5);
      },
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        // Sync our controller text to the autocomplete controller
        if (controller.text != _nameController.text &&
            _nameController.text.isNotEmpty) {
          controller.text = _nameController.text;
        }

        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: context.l10n.productName,
            hintStyle: AppTextStyles.bodySmall
                .copyWith(color: context.textTertiaryColor),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            isDense: true,
            border: InputBorder.none,
          ),
          onChanged: (val) {
            _nameController.text = val;
            _updateItem(productName: val);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxHeight: 200, maxWidth: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option,
                        style: AppTextStyles.bodySmall),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (selected) {
        _nameController.text = selected;
        _updateItem(productName: selected);
      },
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          InkWell(
            onTap: _decrementQuantity,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Icon(Icons.remove, size: 16,
                  color: context.textSecondaryColor),
            ),
          ),
          // Quantity input
          SizedBox(
            width: 40,
            child: TextField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                final qty = double.tryParse(val);
                if (qty != null && qty > 0) {
                  _updateItem(quantity: qty);
                }
              },
            ),
          ),
          // Increment
          InkWell(
            onTap: _incrementQuantity,
            borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Icon(Icons.add, size: 16,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
