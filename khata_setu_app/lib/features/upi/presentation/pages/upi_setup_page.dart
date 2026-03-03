import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/shop_upi_cubit.dart';
import '../bloc/shop_upi_state.dart';

class UpiSetupPage extends StatefulWidget {
  const UpiSetupPage({super.key});

  @override
  State<UpiSetupPage> createState() => _UpiSetupPageState();
}

class _UpiSetupPageState extends State<UpiSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _merchantCodeController = TextEditingController();

  bool _isLoading = false;
  String? _existingId;
  String? _qrImagePath;

  static final _upiRegex = RegExp(r'^[\w.\-]+@[\w]+$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopUpiCubit>().loadConfig();
    });
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _shopNameController.dispose();
    _merchantCodeController.dispose();
    super.dispose();
  }

  void _populateFromConfig(ShopUpiState state) {
    if (state is ShopUpiLoaded && state.config != null) {
      final c = state.config!;
      if (_upiIdController.text.isEmpty) {
        _upiIdController.text = c.upiId;
        _shopNameController.text = c.shopName;
        _merchantCodeController.text = c.merchantCode ?? '';
        _existingId = c.id;
        _qrImagePath = c.qrImagePath;
      }
    }
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    await context.read<ShopUpiCubit>().saveConfig(
      upiId: _upiIdController.text.trim(),
      shopName: _shopNameController.text.trim(),
      merchantCode: _merchantCodeController.text.trim().isEmpty
          ? null
          : _merchantCodeController.text.trim(),
      existingId: _existingId,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _pickQrImage() async {
    if (_existingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.saveUpiFirst),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      await context.read<ShopUpiCubit>().saveQrImage(_existingId!, bytes);
      setState(() => _qrImagePath = picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToPickImage(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeQrImage() async {
    if (_existingId == null) return;
    await context.read<ShopUpiCubit>().removeQrImage(_existingId!);
    setState(() => _qrImagePath = null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.upiSetup),
          elevation: 0,
        ),
        body: BlocConsumer<ShopUpiCubit, ShopUpiState>(
          listener: (context, state) {
            _populateFromConfig(state);

            if (state is ShopUpiSaved) {
              _existingId = state.config.id;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(context.l10n.upiSaved),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }

            if (state is ShopUpiQrUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.qrImageUpdated),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }

            if (state is ShopUpiError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ShopUpiLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── UPI Info Section ──
                    AnimatedListItem(
                      index: 0,
                      child: _buildSectionCard(
                        context.l10n.upiDetails,
                        Icons.account_balance_wallet_rounded,
                        AppColors.primary,
                        isDark,
                        children: [
                          CustomTextField(
                            controller: _upiIdController,
                            label: context.l10n.upiIdLabel,
                            hint: context.l10n.upiIdPlaceholder,
                            prefixIcon: Icons.alternate_email_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return context.l10n.upiIdRequired;
                              }
                              if (!_upiRegex.hasMatch(v.trim())) {
                                return context.l10n.upiIdInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CustomTextField(
                            controller: _shopNameController,
                            label: context.l10n.shopNameStar,
                            hint: context.l10n.upiShopNameHint,
                            prefixIcon: Icons.store_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return context.l10n.shopNameRequired;
                              }
                              if (v.trim().length < 2) {
                                return context.l10n.shopNameMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CustomTextField(
                            controller: _merchantCodeController,
                            label: context.l10n.merchantCodeOptional,
                            hint: context.l10n.merchantCodeHint,
                            prefixIcon: Icons.code_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── QR Upload Section ──
                    AnimatedListItem(
                      index: 1,
                      child: _buildSectionCard(
                        context.l10n.qrCodeImage,
                        Icons.qr_code_rounded,
                        AppColors.teal,
                        isDark,
                        children: [
                          Text(
                            context.l10n.qrUploadDescription,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: context.textSecondaryColor),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_qrImagePath != null) ...[
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              child: Image.file(
                                File(_qrImagePath!),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: context.glassColor,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Center(
                                      child:
                                          Text(context.l10n.unableToLoadQrImage)),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Replace',
                                    isOutlined: true,
                                    isFullWidth: false,
                                    icon: Icons.swap_horiz_rounded,
                                    onPressed: _pickQrImage,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Remove',
                                    isOutlined: true,
                                    isFullWidth: false,
                                    icon: Icons.delete_outline_rounded,
                                    onPressed: _removeQrImage,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _pickQrImage,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: context.glassColor,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: context.glassBorderColor,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.teal.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.cloud_upload_rounded,
                                          color: AppColors.teal,
                                          size: 28),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(context.l10n.tapToUploadQrImage,
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                                color: context
                                                    .textPrimaryColor)),
                                    const SizedBox(height: 4),
                                    Text(context.l10n.imageFormatHint,
                                        style: AppTextStyles.caption.copyWith(
                                            color: context
                                                .textSecondaryColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── UPI URI Preview ──
                    if (_upiIdController.text.isNotEmpty) ...[
                      AnimatedListItem(
                        index: 2,
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview_rounded,
                                      size: 18,
                                      color: context.textSecondaryColor),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(context.l10n.upiUriPreview,
                                      style: AppTextStyles.labelMedium.copyWith(
                                          color: context.textSecondaryColor)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: context.glassColor,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'upi://pay?pa=${_upiIdController.text.trim()}&pn=${_shopNameController.text.trim()}&cu=INR',
                                  style: AppTextStyles.caption.copyWith(
                                    color: context.textPrimaryColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Save Button ──
                    AnimatedListItem(
                      index: 3,
                      child: CustomButton(
                        text: _existingId != null
                            ? context.l10n.updateUpiDetails
                            : context.l10n.saveUpiDetails,
                        onPressed: _onSave,
                        isLoading: _isLoading,
                        icon: Icons.save_rounded,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          },
        ),
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
            color: AppColors.black.withOpacity(isDark ? 0.2 : 0.1),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style:
                      AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
