import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/daily_note_model.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../../../customers/presentation/bloc/customer_state.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_state.dart';
import '../bloc/daily_note_bloc.dart';
import '../bloc/daily_note_event.dart';
import '../bloc/daily_note_state.dart';
import '../widgets/daily_item_row.dart';
import '../widgets/frequent_products_chips.dart';

class DailyNoteEditorPage extends StatefulWidget {
  final String? noteId;
  final String? customerId;
  final String? customerName;

  const DailyNoteEditorPage({
    super.key,
    this.noteId,
    this.customerId,
    this.customerName,
  });

  @override
  State<DailyNoteEditorPage> createState() => _DailyNoteEditorPageState();
}

class _DailyNoteEditorPageState extends State<DailyNoteEditorPage>
    with SingleTickerProviderStateMixin {
  late final DailyNoteBloc _bloc;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _productNames = [];

  @override
  void initState() {
    super.initState();
    _bloc = getIt<DailyNoteBloc>();
    _bloc.add(LoadNoteForEdit(
      noteId: widget.noteId,
      customerId: widget.customerId,
      customerName: widget.customerName,
    ));
    _loadProductNames();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  void _loadProductNames() {
    try {
      final inventoryBloc = getIt<InventoryBloc>();
      final state = inventoryBloc.state;
      if (state is InventoryLoaded) {
        _productNames =
            state.products.map((p) => p.name).toSet().toList()..sort();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewItem({String? productName, double? price, String? unit}) {
    final item = DailyItemModel(
      productName: productName ?? '',
      quantity: 1,
      unitPrice: price ?? 0,
      unit: unit,
      timeLabel: _getCurrentTimeLabel(),
    );
    _bloc.add(AddItem(item));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _getCurrentTimeLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 0;
    if (hour < 17) return 1;
    return 2;
  }

  void _saveNote() {
    _bloc.add(const SaveNote());
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    final currentState = _bloc.state;
    if (currentState is DailyNoteEditing) {
      final newTags = List<String>.from(currentState.note.tags);
      if (!newTags.contains(trimmed)) {
        newTags.add(trimmed);
        _bloc.add(UpdateNoteField(tags: newTags));
      }
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    final currentState = _bloc.state;
    if (currentState is DailyNoteEditing) {
      final newTags = List<String>.from(currentState.note.tags)
        ..remove(tag);
      _bloc.add(UpdateNoteField(tags: newTags));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyNoteBloc, DailyNoteState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is DailyNoteSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.noteSavedSuccess),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
        if (state is DailyNoteDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note deleted'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
        if (state is DailyNoteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.credit,
            ),
          );
        }
        if (state is DailyNoteEditing) {
          // Sync text controllers only when first entering editing state
          if (_titleController.text.isEmpty && state.note.title.isNotEmpty) {
            _titleController.text = state.note.title;
          }
          if (_descController.text.isEmpty &&
              (state.note.description?.isNotEmpty ?? false)) {
            _descController.text = state.note.description!;
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AmbientBackground(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildHeader(context, state),
                    Expanded(
                      child: _buildBodyContent(context, state),
                    ),
                    if (state is DailyNoteEditing)
                      _buildBottomBar(context, state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, DailyNoteState state) {
    final dateStr = state is DailyNoteEditing
        ? DateFormat('dd MMM yyyy')
            .format(state.note.noteDate ?? DateTime.now())
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    final isEditing = state is DailyNoteEditing;
    final title = isEditing && !state.isNew
        ? (state.note.title.isNotEmpty ? state.note.title : 'Edit Note')
        : context.l10n.newDailyNote;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(12),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: context.textPrimaryColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(text: title, style: AppTextStyles.h4),
                Text(dateStr,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.textSecondaryColor)),
              ],
            ),
          ),
          // Delete button (for existing notes)
          if (isEditing && !state.isNew)
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () =>
                    _showDeleteConfirmation(context, state.note.id),
                borderRadius: BorderRadius.circular(12),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.credit),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Body Content (state-aware) ──────────────────────────────

  /// Handles all BLoC states and renders appropriate UI.
  /// This ensures the editor never shows blank in any state.
  Widget _buildBodyContent(BuildContext context, DailyNoteState state) {
    // Primary state: editing a note
    if (state is DailyNoteEditing) {
      return _buildEditorBody(context, state);
    }
    
    // Loading state
    if (state is DailyNoteLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Error state - show error message with retry
    if (state is DailyNoteError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.credit),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _bloc.add(LoadNoteForEdit(
                  noteId: widget.noteId,
                  customerId: widget.customerId,
                  customerName: widget.customerName,
                )),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    
    // Unexpected state (DailyNotesLoaded, DailyNoteInitial, etc.)
    // This can happen on first build before LoadNoteForEdit is processed
    // Show loading and trigger the event again if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bloc.state is! DailyNoteEditing && _bloc.state is! DailyNoteLoading) {
        _bloc.add(LoadNoteForEdit(
          noteId: widget.noteId,
          customerId: widget.customerId,
          customerName: widget.customerName,
        ));
      }
    });
    return const Center(child: CircularProgressIndicator());
  }

  // ─── Editor Body ─────────────────────────────────────────────

  Widget _buildEditorBody(BuildContext context, DailyNoteEditing state) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Title field (required)
        SurfaceCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: TextField(
            controller: _titleController,
            style: AppTextStyles.bodyLarge
                .copyWith(fontWeight: FontWeight.w600),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Note title *',
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: context.textTertiaryColor,
                  fontWeight: FontWeight.w600),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              prefixIcon: Icon(Icons.title_rounded,
                  color: AppColors.primary, size: 20),
            ),
            onChanged: (val) =>
                _bloc.add(UpdateNoteField(title: val)),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Priority & Customer row
        Row(
          children: [
            // Priority selector
            Expanded(child: _buildPrioritySelector(context, state)),
            const SizedBox(width: AppSpacing.sm),
            // Customer (optional)
            Expanded(child: _buildCustomerSelector(context, state)),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Tags
        _buildTagsSection(context, state),

        // Frequent products chips
        if (state.frequentProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          FrequentProductsChips(
            products: state.frequentProducts,
            onTap: (name) {
              final product = _findProduct(name);
              _addNewItem(
                productName: name,
                price: product?.sellingPrice,
                unit: product?.unit,
              );
            },
          ),
        ],

        // Repeat yesterday button
        if (state.hasYesterdayNote &&
            state.note.customerId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SurfaceCard(
            onTap: () => _bloc.add(
                RepeatYesterdayNote(state.note.customerId!)),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(context.l10n.repeatYesterday,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Time-labelled sections
        _buildTimeLabelSection(context, 0, Icons.wb_sunny_outlined, state),
        _buildTimeLabelSection(context, 1, Icons.wb_cloudy_outlined, state),
        _buildTimeLabelSection(context, 2, Icons.nightlight_outlined, state),

        const SizedBox(height: AppSpacing.md),

        // Add item button
        _buildAddItemButton(context),

        const SizedBox(height: AppSpacing.md),

        // Description field
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: TextField(
            controller: _descController,
            onChanged: (text) =>
                _bloc.add(UpdateNoteField(description: text)),
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: context.l10n.addNoteOptional,
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: context.textTertiaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
              prefixIcon: Icon(Icons.note_outlined,
                  color: context.textTertiaryColor, size: 20),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Summary card
        _buildSummaryCard(context, state),

        const SizedBox(height: 100), // Space for bottom bar
      ],
    );
  }

  // ─── Priority Selector ───────────────────────────────────────

  Widget _buildPrioritySelector(
      BuildContext context, DailyNoteEditing state) {
    const priorities = [
      ('low', Icons.arrow_downward_rounded, 'Low'),
      ('medium', Icons.remove_rounded, 'Med'),
      ('high', Icons.arrow_upward_rounded, 'High'),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: Row(
        children: priorities.map((entry) {
          final (value, icon, label) = entry;
          final selected = state.note.priority == value;
          final color = value == 'high'
              ? AppColors.credit
              : value == 'low'
                  ? AppColors.info
                  : AppColors.warning;

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  _bloc.add(UpdateNoteField(priority: value)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 16,
                        color: selected
                            ? color
                            : context.textTertiaryColor),
                    Text(label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? color
                              : context.textTertiaryColor,
                          fontWeight: selected
                              ? FontWeight.w700
                              : null,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Customer Selector ───────────────────────────────────────

  Widget _buildCustomerSelector(
      BuildContext context, DailyNoteEditing state) {
    return SurfaceCard(
      onTap: () => _showCustomerPicker(context, state),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            state.note.customerId != null
                ? Icons.person_rounded
                : Icons.person_add_alt_rounded,
            size: 18,
            color: state.note.customerId != null
                ? AppColors.primary
                : context.textTertiaryColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              state.note.customerName ??
                  (state.note.customerId != null
                      ? 'Customer'
                      : 'No customer'),
              style: AppTextStyles.bodySmall.copyWith(
                color: state.note.customerId != null
                    ? null
                    : context.textTertiaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state.note.customerId != null)
            GestureDetector(
              onTap: () => _bloc.add(const UpdateNoteField(
                  customerId: '', customerName: '')),
              child: Icon(Icons.close_rounded,
                  size: 16, color: context.textTertiaryColor),
            ),
        ],
      ),
    );
  }

  void _showCustomerPicker(
      BuildContext context, DailyNoteEditing state) {
    final customerBloc = context.read<CustomerBloc>();
    final customerState = customerBloc.state;
    if (customerState is! CustomerLoaded) return;

    final customers = customerState.customers;
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noCustomersYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(context.l10n.selectCustomer,
                  style: AppTextStyles.h4),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: customers.length,
                itemBuilder: (_, i) {
                  final c = customers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: Text(c.name[0].toUpperCase(),
                          style:
                              TextStyle(color: AppColors.primary)),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.phone),
                    onTap: () {
                      Navigator.pop(ctx);
                      _bloc.add(UpdateNoteField(
                        customerId: c.id,
                        customerName: c.name,
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tags Section ────────────────────────────────────────────

  Widget _buildTagsSection(BuildContext context, DailyNoteEditing state) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing tags
          if (state.note.tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: 2,
              children: state.note.tags
                  .map((tag) => Chip(
                        label: Text(tag,
                            style: AppTextStyles.labelSmall),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      ))
                  .toList(),
            ),
          // Add tag field
          TextField(
            controller: _tagController,
            style: AppTextStyles.bodySmall,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Add tag...',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: context.textTertiaryColor),
              prefixIcon: Icon(Icons.label_outline_rounded,
                  size: 18, color: context.textTertiaryColor),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: _addTag,
          ),
        ],
      ),
    );
  }

  // ─── Time Label Sections ─────────────────────────────────────

  Widget _buildTimeLabelSection(
    BuildContext context,
    int timeLabel,
    IconData icon,
    DailyNoteEditing state,
  ) {
    final items =
        state.note.items.where((i) => i.timeLabel == timeLabel).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final labels = [
      context.l10n.morningLabel,
      context.l10n.afternoonLabel,
      context.l10n.eveningLabel,
    ];
    final colors = [
      AppColors.warning,
      AppColors.primary,
      AppColors.info,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colors[timeLabel]),
            const SizedBox(width: AppSpacing.xs),
            Text(labels[timeLabel],
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors[timeLabel],
                  fontWeight: FontWeight.w600,
                )),
            const Spacer(),
            Text(
              '${AppConstants.currencySymbol}${items.fold(0.0, (s, i) => s + i.totalPrice).toStringAsFixed(0)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors[timeLabel],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ...items.map((item) => DailyItemRow(
              item: item,
              productNames: _productNames,
              onUpdate: (updated) => _bloc.add(UpdateItem(updated)),
              onRemove: () => _bloc.add(RemoveItem(item.id)),
            )),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ─── Add Item Button ─────────────────────────────────────────

  Widget _buildAddItemButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _addNewItem(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text(context.l10n.addMoreItems,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  // ─── Summary ─────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, DailyNoteEditing state) {
    return SurfaceCard(
      gradient: AppGradients.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.total,
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
              Text(AppFormatter.currencyWhole(state.totalAmount),
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.itemCount} ${context.l10n.itemsHeader}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8)),
              ),
              // Priority badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  state.note.priority.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, DailyNoteEditing state) {
    return SurfaceCard(
      borderRadius: 0,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: state.isSaving ||
                  state.note.title.trim().isEmpty
              ? null
              : _saveNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
          ),
          child: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(context.l10n.saveDailyNote,
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  ProductModel? _findProduct(String name) {
    try {
      final inventoryBloc = getIt<InventoryBloc>();
      final state = inventoryBloc.state;
      if (state is InventoryLoaded) {
        return state.products
            .where(
                (p) => p.name.toLowerCase() == name.toLowerCase())
            .firstOrNull;
      }
    } catch (_) {}
    return null;
  }

  void _showDeleteConfirmation(BuildContext context, String noteId) {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 48, color: AppColors.credit),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.deleteNote, style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.deleteNoteConfirm,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondaryColor),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _bloc.add(DeleteNote(noteId));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.credit,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.l10n.delete),
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
