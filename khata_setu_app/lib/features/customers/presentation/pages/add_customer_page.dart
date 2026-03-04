import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  String _selectedAvatar = '👤';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _avatarEmojis = [
    '👤', '👨', '👩', '🧑', '👴', '👵', '🧔', '👳',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final creditLimit = double.tryParse(_creditLimitController.text) ?? 5000.0;

      context.read<CustomerBloc>().add(AddCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        creditLimit: creditLimit,
        avatar: _selectedAvatar,
      ));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
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
              Text(
                context.l10n.customerAddedTitle,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.customerAddedMessage(_nameController.text),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.addAnother,
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: context.l10n.done,
                      onPressed: () {
                        Navigator.pop(context);
                        this.context.pop();
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
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _creditLimitController.clear();
    _notesController.clear();
    setState(() {
      _currentStep = 0;
      _selectedAvatar = '👤';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerAdded) {
          setState(() => _isLoading = false);
          _showSuccessDialog();
        } else if (state is CustomerError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addCustomer),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _nameController.text.isNotEmpty ? _onSave : null,
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.l10n.save),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar picker
                AnimatedListItem(
                  index: 0,
                  child: _buildAvatarSection(isDark),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Progress indicator
                AnimatedListItem(
                  index: 1,
                  child: _buildProgressIndicator(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Personal Info Section
                AnimatedListItem(
                  index: 2,
                  child: _buildSectionCard(
                    context.l10n.personalInfo,
                    Icons.person,
                    AppColors.primary,
                    isDark,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: '${context.l10n.customerName} *',
                        hint: context.l10n.enterFullName,
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.validateName(v, l10n: context.l10n),
                        onChanged: (val) {
                          setState(() {
                            if (val.isNotEmpty && _currentStep < 1) {
                              _currentStep = 1;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _phoneController,
                        label: '${context.l10n.customerPhone} *',
                        hint: context.l10n.enterPhoneNumber,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (v) => Validators.validatePhone(v, l10n: context.l10n),
                        onChanged: (val) {
                          setState(() {
                            if (val.length == 10 && _currentStep < 2) {
                              _currentStep = 2;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Contact Info Section
                AnimatedListItem(
                  index: 3,
                  child: _buildSectionCard(
                    context.l10n.contactDetails,
                    Icons.contact_mail,
                    AppColors.info,
                    isDark,
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        label: context.l10n.customerEmail,
                        hint: context.l10n.customerEmailHint,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => Validators.validateEmail(v, l10n: context.l10n),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _addressController,
                        label: context.l10n.customerAddress,
                        hint: context.l10n.enterFullAddress,
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Credit Settings Section
                AnimatedListItem(
                  index: 4,
                  child: _buildSectionCard(
                    context.l10n.creditSettings,
                    Icons.account_balance_wallet,
                    AppColors.warning,
                    isDark,
                    children: [
                      CustomTextField(
                        controller: _creditLimitController,
                        label: context.l10n.creditLimitOptional,
                        hint: context.l10n.maxCreditAllowed,
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final amount = double.tryParse(value);
                            if (amount == null || amount < 0) {
                              return context.l10n.enterValidAmount;
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Quick credit limit buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [1000, 2000, 5000, 10000, 20000].map((amt) {
                          final isSelected =
                              _creditLimitController.text == amt.toString();
                          return AnimatedScaleOnTap(
                            onTap: () {
                              setState(() {
                                _creditLimitController.text = amt.toString();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey300,
                                ),
                              ),
                              child: Text(
                                '₹${_formatAmount(amt)}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Notes Section
                AnimatedListItem(
                  index: 5,
                  child: _buildSectionCard(
                    context.l10n.notesSection,
                    Icons.notes,
                    AppColors.secondary,
                    isDark,
                    children: [
                      CustomTextField(
                        controller: _notesController,
                        label: context.l10n.customerNotes,
                        hint: context.l10n.customerNotesHint,
                        prefixIcon: Icons.edit_note,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Button
                AnimatedListItem(
                  index: 6,
                  child: CustomButton(
                    text: context.l10n.addCustomer,
                    onPressed: _onSave,
                    isLoading: _isLoading,
                    icon: Icons.person_add,
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

  Widget _buildAvatarSection(bool isDark) {
    return Column(
      children: [
        // Main avatar
        AnimatedScaleOnTap(
          onTap: () => _showAvatarPicker(),
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _selectedAvatar,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.tapToChangeAvatar,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.chooseAvatar,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _avatarEmojis.map((emoji) {
                  final isSelected = _selectedAvatar == emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatar = emoji);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.grey100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [context.l10n.name, context.l10n.phone, context.l10n.detailsTab, context.l10n.save];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isCompleted = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : AppColors.grey200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: AppColors.white)
                            : Text(
                                '${i + 1}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isActive
                                      ? AppColors.white
                                      : AppColors.grey500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? AppColors.primary : AppColors.grey400,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    color: isCompleted ? AppColors.success : AppColors.grey200,
                    margin: const EdgeInsets.only(bottom: 16),
                  ),
                ),
            ],
          ),
        );
      }),
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

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toString();
  }
}
