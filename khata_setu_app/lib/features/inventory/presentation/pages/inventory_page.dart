import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/cart_manager.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/premium_animations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/repositories/udhar_repository.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _cartManager = getIt<CartManager>();
  String _selectedCategory = 'All';
  late TabController _tabController;
  bool _showCart = false;

  List<String> get _categories {
    final state = getIt<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      return ['All', ...state.categories];
    }
    return ['All'];
  }

  List<ProductModel> get _filteredProducts {
    final state = getIt<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      return state.filteredProducts;
    }
    return [];
  }

  List<ProductModel> get _allProducts {
    final state = getIt<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      return state.products;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cartManager.addListener(_onCartChanged);
    // Load products via BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryBloc>().add(const LoadProducts());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final size = MediaQuery.of(context).size;

    return BlocConsumer<InventoryBloc, InventoryState>(
        listenWhen: (prev, curr) => 
            curr is InventoryActionSuccess || curr is InventoryError,
        listener: (context, state) {
          if (state is InventoryActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        // Don't rebuild on InventoryActionSuccess - it's a transient notification state
        buildWhen: (prev, curr) => curr is! InventoryActionSuccess,
        builder: (context, state) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(isDark),
                _buildGlassTabBar(isDark),
                Expanded(
                  child: _buildContentForState(state, isDark),
                ),
              ],
            ),
            if (_cartManager.itemCount > 0) _buildCartPreview(isDark),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _showCart ? 0 : -size.height * 0.7,
              left: 0,
              right: 0,
              height: size.height * 0.7,
              child: _buildFullCart(isDark),
            ),
          ],
        ),
      ),
      // Always show FAB (except during error)
      floatingActionButton: (state is! InventoryError)
          ? Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.circular),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push('/inventory/add');
                  // Reload products after returning from add page
                  context.read<InventoryBloc>().add(const LoadProducts());
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  context.l10n.addProduct,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
        },
    );
  }

  /// Build content based on current inventory state
  Widget _buildContentForState(InventoryState state, bool isDark) {
    // Initial or Loading state - show shimmer
    if (state is InventoryInitial || state is InventoryLoading) {
      return _buildLoadingShimmer(isDark);
    }

    // Error state - show error with retry
    if (state is InventoryError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, 
                size: 56, 
                color: AppColors.error.withOpacity(0.6)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                style: const TextStyle(fontSize: 14, color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.read<InventoryBloc>().add(const LoadProducts()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    // Empty state - show CTA to add first product
    if (state is InventoryEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined, 
                size: 64, 
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.noProductsAddedYet,
              style: AppTextStyles.h4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addFirstProductHint,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/inventory/add');
                  context.read<InventoryBloc>().add(const LoadProducts());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  context.l10n.addProduct,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loaded state - show TabBarView
    if (state is InventoryLoaded) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildShopView(isDark),
          _buildInventoryView(isDark),
        ],
      );
    }

    // Default fallback - show loading shimmer for any unknown state
    return _buildLoadingShimmer(isDark);
  }

  /// Shimmer loading placeholders for inventory
  Widget _buildLoadingShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Category shimmer
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                width: 80,
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Product grid shimmer
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey800 : AppColors.grey200,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.grey300,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.grey700 : AppColors.grey300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: 60,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.grey700 : AppColors.grey300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildAppBar(bool isDark) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  context.l10n.shopAndInventory,
                  style: AppTextStyles.h2.copyWith(
                    color: context.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                GradientBadge(
                  label: context.l10n.lowStockCount(
                    _allProducts.where((p) => p.isLowStock).length,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.7),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
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
                      context.read<InventoryBloc>().add(SearchProducts(query));
                      setState(() {});
                    },
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchProducts,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                      prefixIcon: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppGradients.primaryGradient.createShader(b),
                        child: const Icon(Icons.search_rounded, size: 22),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: context.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<InventoryBloc>().add(const SearchProducts(''));
                                setState(() {});
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
      ),
    );
  }

  Widget _buildGlassTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: context.glassGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: context.glassBorderColor),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: context.textSecondaryColor,
              labelStyle: AppTextStyles.labelLarge,
              tabs: [
                Tab(text: '🛒 ${context.l10n.shopTab}'),
                Tab(text: '📦 ${context.l10n.inventoryTab}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopView(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: SpringContainer(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    context.read<InventoryBloc>().add(FilterByCategory(
                      category == 'All' ? null : category,
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppGradients.primaryGradient
                          : null,
                      color: isSelected ? null : context.glassColor,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : context.glassBorderColor,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? PremiumEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: context.l10n.noProductsFound,
                  subtitle: context.l10n.tryChangingFiltersOrSearch,
                )
              : GridView.builder(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom: _cartManager.itemCount > 0
                        ? AppSpacing.navClearance + 20
                        : AppSpacing.navClearance,
                  ),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.responsive.gridCrossAxisCount,
                    childAspectRatio: context.responsive.gridChildAspectRatio,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return AnimatedListItem(
                      index: index,
                      child: _GlassProductCard(
                        product: product,
                        cartManager: _cartManager,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryView(bool isDark) {
    return _allProducts.isEmpty
        ? PremiumEmptyState(
            icon: Icons.inventory_2_outlined,
            title: context.l10n.noProductsFound,
            subtitle: context.l10n.tryChangingFiltersOrSearch,
          )
        : ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.navClearance,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        return AnimatedListItem(
          index: index,
          child: _GlassInventoryCard(
            product: product,
            isDark: isDark,
            onEdit: () => _showEditProductSheet(product),
            onStockUpdate: () => _showStockUpdateSheet(product),
            onDelete: () {
              context.read<InventoryBloc>().add(DeleteProduct(product.id));
            },
          ),
        );
      },
    );
  }

  Widget _buildCartPreview(bool isDark) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedListItem(
        index: 0,
        beginOffset: const Offset(0, 1),
        child: GestureDetector(
          onTap: () => setState(() => _showCart = true),
          onVerticalDragUpdate: (d) {
            if (d.delta.dy < -5) setState(() => _showCart = true);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Badge(
                          label: Text('${_cartManager.itemCount}'),
                          child: const Icon(
                            Icons.shopping_cart_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_cartManager.totalQuantity} ${context.l10n.itemsInCart(_cartManager.totalQuantity)}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '₹${_cartManager.total.toStringAsFixed(0)}',
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.viewCart,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.primary,
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
      ),
    );
  }

  Widget _buildFullCart(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xxl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.cardColor.withOpacity(0.95),
                context.backgroundColor.withOpacity(0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border(top: BorderSide(color: context.glassBorderColor)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.glassBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    GradientText(
                      text: context.l10n.yourCart,
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GradientBadge(
                      label: context.l10n.itemsCount(_cartManager.itemCount),
                      gradient: AppGradients.primaryGradient,
                    ),
                    const Spacer(),
                    SpringContainer(
                      onTap: () => setState(() => _showCart = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.glassColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.glassBorderColor),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: _cartManager.items.length,
                  itemBuilder: (context, index) {
                    final item = _cartManager.items[index];
                    return _GlassCartItemTile(
                      item: item,
                      cartManager: _cartManager,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              GlassCard(
                margin: const EdgeInsets.all(AppSpacing.md),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.subtotal,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                          Text(
                            '₹${_cartManager.subtotal.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_cartManager.discount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.discount,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              '-₹${_cartManager.discount.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Container(
                          height: 1,
                          color: context.glassBorderColor,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.total,
                            style: AppTextStyles.h4.copyWith(
                              color: context.textPrimaryColor,
                            ),
                          ),
                          CountingText(
                            value: _cartManager.total,
                            prefix: '₹',
                            formatAsCompact: false,
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: SpringContainer(
                              onTap: () {
                                _cartManager.clearCart();
                                setState(() => _showCart = false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xl,
                                  ),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.clear,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: MorphingGradientButton(
                              label: context.l10n.checkout,
                              icon: Icons.receipt_long_rounded,
                              gradient: AppGradients.successGradient,
                              width: double.infinity,
                              onTap: _showCheckoutDialog,
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
        ),
      ),
    );
  }

  void _showEditProductSheet(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final localNameController = TextEditingController(text: product.localName ?? '');
    final purchasePriceController = TextEditingController(
      text: product.purchasePrice.toStringAsFixed(0),
    );
    final sellingPriceController = TextEditingController(
      text: product.sellingPrice.toStringAsFixed(0),
    );
    final minStockController = TextEditingController(
      text: product.minStockLevel.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showGlassBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryActionSuccess) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(this.context.l10n.productUpdatedSuccess),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(
                    text: context.l10n.editProduct,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Product Name
                  _editField(context.l10n.productName, nameController,
                      Icons.inventory_2_outlined),
                  const SizedBox(height: AppSpacing.sm),

                  // Local Name
                  _editField('Local Name', localNameController,
                      Icons.translate_rounded),
                  const SizedBox(height: AppSpacing.sm),

                  // Prices Row
                  Row(
                    children: [
                      Expanded(
                        child: _editField(
                          context.l10n.buyPriceRequired,
                          purchasePriceController,
                          Icons.currency_rupee,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _editField(
                          context.l10n.sellPriceRequired,
                          sellingPriceController,
                          Icons.currency_rupee,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Min Stock Level
                  _editField(context.l10n.minStockAlert, minStockController,
                      Icons.inventory_outlined,
                      isNumber: true),
                  const SizedBox(height: AppSpacing.lg),

                  // Save Button
                  MorphingGradientButton(
                    label: context.l10n.updateProduct,
                    icon: Icons.save_rounded,
                    gradient: AppGradients.primaryGradient,
                    width: double.infinity,
                    onTap: () {
                      if (formKey.currentState?.validate() ?? false) {
                        context.read<InventoryBloc>().add(UpdateProduct(
                              productId: product.id,
                              name: nameController.text.trim(),
                              localName: localNameController.text.trim().isNotEmpty
                                  ? localNameController.text.trim()
                                  : null,
                              category: product.category,
                              unit: product.unit,
                              purchasePrice:
                                  double.tryParse(purchasePriceController.text) ??
                                      product.purchasePrice,
                              sellingPrice:
                                  double.tryParse(sellingPriceController.text) ??
                                      product.sellingPrice,
                              mrp: product.mrp,
                              taxRate: product.taxRate,
                              minStockLevel:
                                  double.tryParse(minStockController.text) ??
                                      product.minStockLevel,
                              description: product.description,
                              image: product.image,
                              tags: product.tags,
                              supplierName: product.supplierName,
                              supplierPhone: product.supplierPhone,
                              expiryDate: product.expiryDate,
                            ));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller,
      IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
    );
  }

  void _showStockUpdateSheet(ProductModel product) {
    final controller = TextEditingController();
    bool isAdd = true;

    showGlassBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                text: context.l10n.updateStock,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${product.name} • ${context.l10n.currentInfo(product.currentStock.toInt(), product.unit)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: context.glassColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() => isAdd = true);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: isAdd
                                ? AppGradients.successGradient
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Center(
                            child: Text(
                              context.l10n.addStockAction,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isAdd
                                    ? Colors.white
                                    : context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() => isAdd = false);
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: !isAdd
                                ? AppGradients.dangerGradient
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Center(
                            child: Text(
                              context.l10n.removeStockAction,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: !isAdd
                                    ? Colors.white
                                    : context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.quantityUnit(product.unit),
                  labelStyle: TextStyle(color: context.textSecondaryColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              MorphingGradientButton(
                label: isAdd
                    ? context.l10n.addStockAction
                    : context.l10n.removeStockAction,
                icon: isAdd ? Icons.add_rounded : Icons.remove_rounded,
                gradient: isAdd
                    ? AppGradients.successGradient
                    : AppGradients.dangerGradient,
                width: double.infinity,
                onTap: () {
                  final qty = int.tryParse(controller.text) ?? 0;
                  if (qty > 0) {
                    context.read<InventoryBloc>().add(AdjustStock(
                      productId: product.id,
                      type: isAdd ? 'add' : 'remove',
                      quantity: qty.toDouble(),
                    ));
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckoutDialog() {
    showGlassBottomSheet(
      context: context,
      builder: (ctx) => _GlassCheckoutSheet(
        cartManager: _cartManager,
        onComplete: () {
          Navigator.pop(ctx);
          setState(() => _showCart = false);
          _cartManager.clearCart();
          _showSuccessDialog();
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientIconBox(
                icon: Icons.check_circle_rounded,
                gradient: AppGradients.successGradient,
                size: 72,
                iconSize: 40,
                borderRadius: 36,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientText(
                text: context.l10n.saleCompleteTitle,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.transactionRecordedSuccess,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              MorphingGradientButton(
                label: context.l10n.done,
                icon: Icons.check_rounded,
                gradient: AppGradients.successGradient,
                width: double.infinity,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ Glass Widgets ═══════════════════════

class _GlassProductCard extends StatelessWidget {
  final ProductModel product;
  final CartManager cartManager;
  final bool isDark;

  const _GlassProductCard({
    required this.product,
    required this.cartManager,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = cartManager.hasProduct(product.id);
    final quantity = cartManager.getQuantity(product.id);

    return SpringContainer(
      onTap: product.isOutOfStock
          ? null
          : () {
              if (!inCart) {
                cartManager.addItem(
                  CartItem(
                    productId: product.id,
                    productName: product.name,
                    price: product.sellingPrice,
                    unit: product.unit,
                  ),
                );
                HapticFeedback.lightImpact();
              }
            },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            if (inCart)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      product.categoryEmoji,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    product.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      GradientText(
                        text: '₹${product.sellingPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      StatusDot(
                        color: product.isOutOfStock
                            ? AppColors.error
                            : product.isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                        size: 8,
                        pulse: product.isLowStock,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.isOutOfStock
                            ? context.l10n.outOfStock
                            : '${product.currentStock.toInt()} ${context.l10n.inStockCount(product.currentStock.toInt())}',
                        style: AppTextStyles.caption.copyWith(
                          color: product.isOutOfStock
                              ? AppColors.error
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (inCart)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => cartManager.decrementQuantity(product.id),
                        child: const Icon(
                          Icons.remove_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$quantity',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (quantity < product.currentStock.toInt())
                            cartManager.incrementQuantity(product.id);
                        },
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (product.isLowStock && !product.isOutOfStock && !inCart)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: GradientBadge(
                  label: context.l10n.lowStock,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            if (product.isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Center(
                    child: GradientBadge(
                      label: context.l10n.outOfStock.toUpperCase(),
                      gradient: AppGradients.dangerGradient,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassInventoryCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onStockUpdate;
  final VoidCallback onDelete;

  const _GlassInventoryCard({
    required this.product,
    required this.isDark,
    required this.onEdit,
    required this.onStockUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.glassColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.glassBorderColor),
              ),
              child: Center(
                child: Text(
                  product.categoryEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      GradientText(
                        text: '₹${product.sellingPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' • ${product.category}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(
                      color: product.isOutOfStock
                          ? AppColors.error
                          : product.isLowStock
                          ? AppColors.warning
                          : AppColors.success,
                      size: 8,
                      pulse: product.isLowStock,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.currentStock.toInt()}',
                      style: AppTextStyles.h4.copyWith(
                        color: product.isLowStock
                            ? AppColors.warning
                            : context.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  product.unit,
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.textSecondaryColor,
              ),
              color: context.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  onTap: onStockUpdate,
                  child: Row(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppGradients.primaryGradient.createShader(b),
                        child: const Icon(Icons.inventory_2_outlined, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.updateStock,
                        style: TextStyle(color: context.textPrimaryColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onEdit,
                  child: Row(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppGradients.primaryGradient.createShader(b),
                        child: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.editProduct,
                        style: TextStyle(color: context.textPrimaryColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.delete,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
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

class _GlassCartItemTile extends StatelessWidget {
  final CartItem item;
  final CartManager cartManager;
  final bool isDark;

  const _GlassCartItemTile({
    required this.item,
    required this.cartManager,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.glassColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.glassBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => cartManager.decrementQuantity(item.productId),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 18,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => cartManager.incrementQuantity(item.productId),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            GradientText(
              text: '₹${item.total.toStringAsFixed(0)}',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCheckoutSheet extends StatefulWidget {
  final CartManager cartManager;
  final VoidCallback onComplete;

  const _GlassCheckoutSheet({
    required this.cartManager,
    required this.onComplete,
  });

  @override
  State<_GlassCheckoutSheet> createState() => _GlassCheckoutSheetState();
}

class _GlassCheckoutSheetState extends State<_GlassCheckoutSheet> {
  String _paymentMode = 'cash';
  bool _addToKhata = false;
  String? _selectedCustomer;

  List<Map<String, String>> get _customers {
    try {
      final repo = getIt<UdharRepository>();
      return repo.getAllCustomers().map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientText(
                  text: context.l10n.checkout,
                  style: AppTextStyles.h3,
                ),
                const Spacer(),
                CountingText(
                  value: widget.cartManager.total,
                  prefix: '₹',
                  formatAsCompact: false,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.paymentMode,
              style: AppTextStyles.labelLarge.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _GlassPaymentChip(
                  label: '💵 ${context.l10n.cash}',
                  isSelected: _paymentMode == 'cash',
                  onTap: () => setState(() => _paymentMode = 'cash'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _GlassPaymentChip(
                  label: '📱 ${context.l10n.upi}',
                  isSelected: _paymentMode == 'upi',
                  onTap: () => setState(() => _paymentMode = 'upi'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _GlassPaymentChip(
                  label: '💳 ${context.l10n.bank}',
                  isSelected: _paymentMode == 'card',
                  onTap: () => setState(() => _paymentMode = 'card'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      GradientIconBox(
                        icon: Icons.book_outlined,
                        gradient: AppGradients.primaryGradient,
                        size: 36,
                        iconSize: 18,
                        borderRadius: 10,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.addToKhata,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: context.textPrimaryColor,
                              ),
                            ),
                            Text(
                              context.l10n.recordAsCustomerCredit,
                              style: AppTextStyles.caption.copyWith(
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _addToKhata,
                        onChanged: (v) => setState(() => _addToKhata = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_addToKhata) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _selectedCustomer,
                      dropdownColor: context.cardColor,
                      decoration: InputDecoration(
                        labelText: context.l10n.selectCustomer,
                        labelStyle: TextStyle(
                          color: context.textSecondaryColor,
                        ),
                      ),
                      items: _customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text('${c['name']} (${c['phone']})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MorphingGradientButton(
              label: context.l10n.completeSale,
              icon: Icons.check_circle_rounded,
              gradient: AppGradients.successGradient,
              width: double.infinity,
              onTap: (_addToKhata && _selectedCustomer == null)
                  ? null
                  : widget.onComplete,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _GlassPaymentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassPaymentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringContainer(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryGradient : null,
          color: isSelected ? null : context.glassColor,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.glassBorderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
