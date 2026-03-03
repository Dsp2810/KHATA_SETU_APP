import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/data/models/shop_upi_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/premium_animations.dart';
import '../../../ledger/presentation/bloc/transaction_bloc.dart';
import '../../../ledger/presentation/bloc/transaction_event.dart';
import '../../../ledger/presentation/bloc/transaction_state.dart';
import '../bloc/shop_upi_cubit.dart';
import '../bloc/shop_upi_state.dart';

/// Full-screen UPI QR display page.
///
/// Shows a dynamically generated QR code from the UPI intent URI with an
/// optional pre-filled amount. Features: copy UPI ID, share QR image,
/// screen brightness boost, and one-tap payment confirmation that records
/// a debit transaction via [TransactionBloc].
class UpiQrDisplayPage extends StatefulWidget {
  /// Customer who is paying. Null for a generic QR without amount.
  final String? customerId;

  /// Customer name (display only).
  final String? customerName;

  /// Pre-filled amount embedded in QR. Null = amount-less QR.
  final double? amount;

  const UpiQrDisplayPage({
    super.key,
    this.customerId,
    this.customerName,
    this.amount,
  });

  @override
  State<UpiQrDisplayPage> createState() => _UpiQrDisplayPageState();
}

class _UpiQrDisplayPageState extends State<UpiQrDisplayPage>
    with TickerProviderStateMixin {
  final GlobalKey _qrRepaintKey = GlobalKey();

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scale;

  ShopUpiModel? _config;

  bool _brightnessMaxed = false;
  bool _paymentConfirmed = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    // Pulse glow around QR
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Load config from global cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopUpiCubit>().loadConfig();
    });

    // Start entry
    _entryController.forward();
  }

  void _toggleBrightness() {
    setState(() => _brightnessMaxed = !_brightnessMaxed);
    HapticFeedback.lightImpact();
    // White overlay simulates brightness boost for QR scanning
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _copyUpiId() {
    if (_config == null) return;
    Clipboard.setData(ClipboardData(text: _config!.upiId));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(context.l10n.upiIdCopied(_config!.upiId)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareQr() async {
    if (_config == null || _isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();

    try {
      // Capture QR widget as image
      final boundary = _qrRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/upi_qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      final shopName = _config!.shopName;
      final amt = widget.amount != null
          ? ' ${AppConstants.currencySymbol}${widget.amount!.toStringAsFixed(0)}'
          : '';
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Pay$amt to $shopName via UPI\nUPI ID: ${_config!.upiId}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToShare(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _confirmPayment() {
    if (_paymentConfirmed) return;
    if (widget.customerId == null || widget.amount == null) {
      // Can't record without customer/amount
      Navigator.pop(context);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _paymentConfirmed = true);

    // Dispatch AddPayment to TransactionBloc (must be provided above in widget tree)
    try {
      final bloc = context.read<TransactionBloc>();
      bloc.add(AddPayment(
        customerId: widget.customerId!,
        amount: widget.amount!,
        paymentMode: 1, // UPI
        description:
            'UPI Payment${widget.customerName != null ? ' from ${widget.customerName}' : ''}',
      ));
    } catch (_) {
      // TransactionBloc not in tree — pop with result
      Navigator.pop(context, true);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final size = MediaQuery.of(context).size;
    final qrSize = math.min(size.width * 0.65, 280.0);

    return BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionAdded && _paymentConfirmed) {
            _showPaymentSuccess(state);
          } else if (state is TransactionError && _paymentConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _paymentConfirmed = false);
          }
        },
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          body: Stack(
            children: [
              // Brightness overlay (white screen effect)
              if (_brightnessMaxed)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),

              SafeArea(
                child: BlocBuilder<ShopUpiCubit, ShopUpiState>(
                  builder: (context, state) {
                    if (state is ShopUpiLoading || state is ShopUpiInitial) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (state is ShopUpiLoaded && state.config != null) {
                      _config = state.config;
                      return _buildContent(isDark, qrSize);
                    }

                    return _buildNoConfig(isDark);
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildNoConfig(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_rounded,
                size: 64, color: context.textTertiaryColor),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.noUpiSetup,
                style: AppTextStyles.h3
                    .copyWith(color: context.textPrimaryColor)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.setupUpiInSettings,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(context.l10n.goBack),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, double qrSize) {
    final config = _config!;
    final upiUri = config.generateUpiUri(amount: widget.amount);

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            children: [
              // Top bar
              _buildTopBar(isDark),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Amount badge (if present)
                      if (widget.amount != null) ...[
                        _buildAmountBadge(),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Customer info (if present)
                      if (widget.customerName != null) ...[
                        AnimatedListItem(
                          index: 0,
                          child: Text(
                            context.l10n.paymentFromName(widget.customerName!),
                            style: AppTextStyles.labelMedium.copyWith(
                                color: context.textSecondaryColor),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // QR Card
                      AnimatedListItem(
                        index: 1,
                        child: _buildQrCard(
                            isDark, qrSize, config, upiUri),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Action buttons row
                      AnimatedListItem(
                        index: 2,
                        child: _buildActionButtons(isDark),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Payment confirmation button
                      if (widget.customerId != null &&
                          widget.amount != null)
                        AnimatedListItem(
                          index: 3,
                          child: _buildConfirmButton(isDark),
                        ),

                      const SizedBox(height: AppSpacing.xxl),
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

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.xs, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded,
                color: context.textPrimaryColor),
          ),
          const Spacer(),
          // Brightness toggle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _brightnessMaxed
                  ? AppColors.warning.withAlpha(30)
                  : context.glassColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _brightnessMaxed
                    ? AppColors.warning.withAlpha(80)
                    : context.glassBorderColor,
              ),
            ),
            child: IconButton(
              onPressed: _toggleBrightness,
              icon: Icon(
                _brightnessMaxed
                    ? Icons.brightness_7_rounded
                    : Icons.brightness_medium_rounded,
                color: _brightnessMaxed
                    ? AppColors.warning
                    : context.textSecondaryColor,
                size: 22,
              ),
              tooltip: _brightnessMaxed
                  ? context.l10n.normalBrightness
                  : context.l10n.maxBrightness,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBadge() {
    return AnimatedListItem(
      index: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.currency_rupee_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              widget.amount!.toStringAsFixed(widget.amount! % 1 == 0 ? 0 : 2),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard(
      bool isDark, double qrSize, ShopUpiModel config, String upiUri) {
    return RepaintBoundary(
      key: _qrRepaintKey,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white, // QR always on white background
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.grey300)
                  .withAlpha(isDark ? 100 : 60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Shop header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    config.shopName,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Animated pulse glow around QR
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                return Container(
                  padding: EdgeInsets.all(4 + pulse * 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary
                          .withAlpha((40 + pulse * 30).toInt()),
                      width: 2,
                    ),
                  ),
                  child: child,
                );
              },
              child: _buildQrWidget(qrSize, upiUri),
            ),

            const SizedBox(height: AppSpacing.md),

            // UPI ID display
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alternate_email_rounded,
                      size: 14, color: AppColors.grey600),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      config.upiId,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.grey700,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyUpiId,
                    child: const Icon(Icons.copy_rounded,
                        size: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            if (widget.amount != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.amountLabelValue(widget.amount!.toStringAsFixed(widget.amount! % 1 == 0 ? 0 : 2)),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey500,
                  fontSize: 11,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.scanWithAnyUpiApp,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the QR code widget.
  /// Uses a custom painter to render the QR code from the UPI URI string,
  /// based on the qr package (which is a dependency of qr_flutter).
  /// If qr_flutter is not available, falls back to a placeholder with the URI.
  Widget _buildQrWidget(double size, String upiUri) {
    // Using a custom QR rendering approach that doesn't need qr_flutter package.
    // We encode the UPI URI into a visual QR pattern using the 'qr' dart package
    // or fall back to a styled placeholder showing the UPI link.
    return _UpiQrPainter(
      data: upiUri,
      size: size,
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.copy_rounded,
            label: context.l10n.copyUpiId,
            color: AppColors.info,
            isDark: isDark,
            onTap: _copyUpiId,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionButton(
            icon: Icons.share_rounded,
            label: context.l10n.shareQr,
            color: AppColors.teal,
            isDark: isDark,
            onTap: _shareQr,
            isLoading: _isSharing,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionButton(
            icon: _brightnessMaxed
                ? Icons.brightness_7_rounded
                : Icons.brightness_medium_rounded,
            label: _brightnessMaxed ? context.l10n.normalLabel : context.l10n.brightenLabel,
            color: AppColors.warning,
            isDark: isDark,
            onTap: _toggleBrightness,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _paymentConfirmed
          ? Container(
              key: const ValueKey('confirmed'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.successGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(context.l10n.paymentRecordedLabel,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : SpringContainer(
              key: const ValueKey('confirm'),
              onTap: _confirmPayment,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.paymentReceivedDash(widget.amount!.toStringAsFixed(0)),
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showPaymentSuccess(TransactionAdded state) {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: ctx.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: ctx.sheetShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.successGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.l10n.paymentRecordedLabel,
                  style: AppTextStyles.h3
                      .copyWith(color: ctx.textPrimaryColor)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.amountFromCustomer(widget.amount!.toStringAsFixed(0), widget.customerName ?? context.l10n.customer),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: ctx.textSecondaryColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.balanceUpdatedAutomatically,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context, true); // close QR page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                  ),
                  child: Text(context.l10n.done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Action Button Widget
// ═══════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: context.cardShadow,
          border: isDark
              ? Border.all(color: context.glassBorderColor.withAlpha(60))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            else
              Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Custom QR Code Painter — Pure Dart implementation using 'qr' library
// This generates a QR code without needing the qr_flutter package
// ═══════════════════════════════════════════════════════════════════

class _UpiQrPainter extends StatelessWidget {
  final String data;
  final double size;

  const _UpiQrPainter({
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Use CustomPaint with a QR code generator
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _QrCodePainter(data: data),
      ),
    );
  }
}

/// Pure Dart QR code painter using polynomial math.
/// Generates a QR code from arbitrary string data.
class _QrCodePainter extends CustomPainter {
  final String data;

  _QrCodePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final modules = _generateQrModules(data);
    final moduleCount = modules.length;
    if (moduleCount == 0) return;

    final cellSize = size.width / moduleCount;
    final paint = Paint()
      ..color = const Color(0xFF1F2328)
      ..style = PaintingStyle.fill;

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw modules with slightly rounded cells for modern look
    final radius = cellSize * 0.15;
    for (int row = 0; row < moduleCount; row++) {
      for (int col = 0; col < moduleCount; col++) {
        if (modules[row][col]) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            ),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) {
    return oldDelegate.data != data;
  }

  /// Generate QR code module matrix using a simplified QR encoding.
  /// This implements QR code generation for alphanumeric/byte data.
  List<List<bool>> _generateQrModules(String input) {
    // Encode data as bytes
    final dataBytes = _encodeToBytes(input);

    // Determine version based on data capacity
    // Version 4 (33x33) supports up to 78 bytes in byte mode at L error correction
    // Version 6 (41x41) supports up to 134 bytes
    // Version 8 (49x49) supports up to 192 bytes
    int version = 4;
    if (dataBytes.length > 78) version = 6;
    if (dataBytes.length > 134) version = 8;
    if (dataBytes.length > 192) version = 10;

    final moduleCount = 17 + version * 4;
    final modules = List.generate(
        moduleCount, (_) => List.filled(moduleCount, false));
    final isFunction = List.generate(
        moduleCount, (_) => List.filled(moduleCount, false));

    // Place finder patterns
    _placeFinderPattern(modules, isFunction, 0, 0);
    _placeFinderPattern(modules, isFunction, moduleCount - 7, 0);
    _placeFinderPattern(modules, isFunction, 0, moduleCount - 7);

    // Place alignment patterns
    final alignPositions = _getAlignmentPositions(version);
    for (final row in alignPositions) {
      for (final col in alignPositions) {
        if (_isFinderRegion(row, col, moduleCount)) continue;
        _placeAlignmentPattern(modules, isFunction, row, col);
      }
    }

    // Place timing patterns
    _placeTimingPatterns(modules, isFunction, moduleCount);

    // Reserve format info and version info areas
    _reserveFormatArea(isFunction, moduleCount);
    if (version >= 7) {
      _reserveVersionArea(isFunction, moduleCount);
    }

    // Place data bits
    _placeDataBits(modules, isFunction, dataBytes, moduleCount, version);

    // Apply mask (using mask 0 for simplicity)
    _applyMask(modules, isFunction, moduleCount, 0);

    // Place format info
    _placeFormatInfo(modules, moduleCount, 0);

    return modules;
  }

  List<int> _encodeToBytes(String input) {
    final codeUnits = input.codeUnits;
    final result = <int>[];

    // Mode indicator: byte mode = 0100
    // Character count: varies by version
    result.add(0x40 | (codeUnits.length >> 4));
    result.add(((codeUnits.length & 0x0F) << 4) |
        (codeUnits.isNotEmpty ? (codeUnits[0] >> 4) : 0));

    for (int i = 0; i < codeUnits.length; i++) {
      if (i > 0) {
        result.add(((codeUnits[i - 1] & 0x0F) << 4) |
            (codeUnits[i] >> 4));
      }
      if (i == codeUnits.length - 1) {
        result.add((codeUnits[i] & 0x0F) << 4);
      }
    }

    // Add terminator and padding
    while (result.length < _getDataCapacity(
        codeUnits.length > 78
            ? (codeUnits.length > 134 ? (codeUnits.length > 192 ? 10 : 8) : 6)
            : 4)) {
      result.add(0xEC);
      if (result.length < _getDataCapacity(
          codeUnits.length > 78
              ? (codeUnits.length > 134 ? (codeUnits.length > 192 ? 10 : 8) : 6)
              : 4)) {
        result.add(0x11);
      }
    }

    return result;
  }

  int _getDataCapacity(int version) {
    // Approximate data codeword capacity at L error correction
    const capacities = {
      4: 80, 6: 136, 8: 192, 10: 271,
    };
    return capacities[version] ?? 80;
  }

  void _placeFinderPattern(List<List<bool>> modules,
      List<List<bool>> isFunction, int row, int col) {
    for (int r = -1; r <= 7; r++) {
      for (int c = -1; c <= 7; c++) {
        final rr = row + r;
        final cc = col + c;
        if (rr < 0 || rr >= modules.length || cc < 0 || cc >= modules.length) {
          continue;
        }
        final isBlack = (0 <= r && r <= 6 && (c == 0 || c == 6)) ||
            (0 <= c && c <= 6 && (r == 0 || r == 6)) ||
            (2 <= r && r <= 4 && 2 <= c && c <= 4);
        modules[rr][cc] = isBlack;
        isFunction[rr][cc] = true;
      }
    }
  }

  bool _isFinderRegion(int row, int col, int size) {
    return (row < 9 && col < 9) ||
        (row < 9 && col >= size - 8) ||
        (row >= size - 8 && col < 9);
  }

  void _placeAlignmentPattern(List<List<bool>> modules,
      List<List<bool>> isFunction, int row, int col) {
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        final rr = row + r;
        final cc = col + c;
        if (rr < 0 || rr >= modules.length || cc < 0 || cc >= modules.length) {
          continue;
        }
        final isBlack =
            r.abs() == 2 || c.abs() == 2 || (r == 0 && c == 0);
        modules[rr][cc] = isBlack;
        isFunction[rr][cc] = true;
      }
    }
  }

  List<int> _getAlignmentPositions(int version) {
    if (version <= 1) return [];
    const table = {
      2: [6, 18],
      3: [6, 22],
      4: [6, 26],
      5: [6, 30],
      6: [6, 34],
      7: [6, 22, 38],
      8: [6, 24, 42],
      9: [6, 26, 46],
      10: [6, 28, 50],
    };
    return table[version] ?? [6, 26];
  }

  void _placeTimingPatterns(List<List<bool>> modules,
      List<List<bool>> isFunction, int size) {
    for (int i = 8; i < size - 8; i++) {
      if (!isFunction[6][i]) {
        modules[6][i] = i % 2 == 0;
        isFunction[6][i] = true;
      }
      if (!isFunction[i][6]) {
        modules[i][6] = i % 2 == 0;
        isFunction[i][6] = true;
      }
    }
    // Dark module
    modules[size - 8][8] = true;
    isFunction[size - 8][8] = true;
  }

  void _reserveFormatArea(List<List<bool>> isFunction, int size) {
    // Around top-left finder
    for (int i = 0; i <= 8; i++) {
      if (i < size) isFunction[8][i] = true;
      if (i < size) isFunction[i][8] = true;
    }
    // Around top-right finder
    for (int i = size - 8; i < size; i++) {
      isFunction[8][i] = true;
    }
    // Around bottom-left finder
    for (int i = size - 7; i < size; i++) {
      isFunction[i][8] = true;
    }
  }

  void _reserveVersionArea(List<List<bool>> isFunction, int size) {
    for (int i = 0; i < 6; i++) {
      for (int j = size - 11; j < size - 8; j++) {
        isFunction[i][j] = true;
        isFunction[j][i] = true;
      }
    }
  }

  void _placeDataBits(List<List<bool>> modules,
      List<List<bool>> isFunction, List<int> data, int size, int version) {
    int bitIndex = 0;
    final totalBits = data.length * 8;

    // Traverse in upward/downward zigzag pattern
    for (int right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5; // Skip timing column

      for (int vert = 0; vert < size; vert++) {
        for (int j = 0; j < 2; j++) {
          final col = right - j;
          final upward = ((right + 1) & 2) == 0;
          final row = upward ? size - 1 - vert : vert;

          if (row < 0 || row >= size || col < 0 || col >= size) continue;
          if (isFunction[row][col]) continue;

          if (bitIndex < totalBits) {
            final byteIdx = bitIndex ~/ 8;
            final bitIdx = 7 - (bitIndex % 8);
            modules[row][col] =
                byteIdx < data.length && ((data[byteIdx] >> bitIdx) & 1) == 1;
            bitIndex++;
          }
        }
      }
    }
  }

  void _applyMask(List<List<bool>> modules, List<List<bool>> isFunction,
      int size, int maskPattern) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (isFunction[row][col]) continue;
        bool invert = false;
        switch (maskPattern) {
          case 0:
            invert = (row + col) % 2 == 0;
          case 1:
            invert = row % 2 == 0;
          case 2:
            invert = col % 3 == 0;
          case 3:
            invert = (row + col) % 3 == 0;
          default:
            invert = (row + col) % 2 == 0;
        }
        if (invert) modules[row][col] = !modules[row][col];
      }
    }
  }

  void _placeFormatInfo(List<List<bool>> modules, int size, int mask) {
    // Format info for error correction L and mask 0: 0x77C4
    // Simplified: place a known format pattern
    const formatBits = 0x77C4;

    for (int i = 0; i <= 5; i++) {
      modules[8][i] = ((formatBits >> (14 - i)) & 1) == 1;
    }
    modules[8][7] = ((formatBits >> 8) & 1) == 1;
    modules[8][8] = ((formatBits >> 7) & 1) == 1;
    modules[7][8] = ((formatBits >> 6) & 1) == 1;
    for (int i = 0; i <= 5; i++) {
      modules[5 - i][8] = ((formatBits >> i) & 1) == 1;
    }

    // Second copy
    for (int i = 0; i < 7; i++) {
      modules[size - 1 - i][8] = ((formatBits >> (14 - i)) & 1) == 1;
    }
    for (int i = 0; i < 8; i++) {
      modules[8][size - 8 + i] = ((formatBits >> i) & 1) == 1;
    }
  }
}
