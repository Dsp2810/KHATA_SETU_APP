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
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  int _currentStep = 0;

  bool _isFormValid = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _selectedBusinessType = 'Kirana Store';

  final List<Map<String, dynamic>> _businessTypes = [
    {'name': 'Kirana Store', 'icon': Icons.shopping_basket},
    {'name': 'Medical Shop', 'icon': Icons.medical_services},
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Clothing', 'icon': Icons.checkroom},
    {'name': 'Hardware', 'icon': Icons.hardware},
    {'name': 'Other', 'icon': Icons.store},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _shopNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final valid = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10 &&
        _shopNameController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _confirmPasswordController.text == _passwordController.text &&
        _agreedToTerms;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  void _onRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.agreeToTermsMessage),
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
      context.read<AuthBloc>().add(RegisterRequested(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            shopName: _shopNameController.text.trim().isNotEmpty
                ? _shopNameController.text.trim()
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, Color(0xFF66BB6A)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.welcomeAboard,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.accountCreatedSuccess,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.shopIsReady(_shopNameController.text.isNotEmpty ? _shopNameController.text : context.l10n.shopName),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: context.l10n.startYourKhata,
                icon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(RouteConstants.dashboard);
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

    return BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated || state is AuthenticatedOffline) {
            _showSuccessDialog();
          } else if (state is AuthError) {
            setState(() => _isLoading = false);
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
        builder: (context, state) {
          // isLoading is available from BlocConsumer for future use
          final _ = state is AuthLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [context.surfaceColor, context.backgroundColor]
                : [AppColors.primary.withValues(alpha: 0.03), AppColors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600
                    ? AppSpacing.xxl
                    : AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button and header
                    AnimatedListItem(
                      index: 0,
                      child: _buildHeader(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Step indicator
                    AnimatedListItem(
                      index: 1,
                      child: _buildStepIndicator(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Form sections
                    AnimatedListItem(
                      index: 2,
                      child: _buildPersonalInfoSection(isDark),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AnimatedListItem(
                      index: 3,
                      child: _buildShopInfoSection(isDark),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AnimatedListItem(
                      index: 4,
                      child: _buildSecuritySection(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Terms & Conditions
                    AnimatedListItem(
                      index: 5,
                      child: _buildTermsCheckbox(isDark),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Register Button
                    AnimatedListItem(
                      index: 6,
                      child: _buildRegisterButton(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Login link
                    AnimatedListItem(
                      index: 7,
                      child: _buildLoginLink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
        },
      );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.grey800
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: isDark ? AppColors.white : AppColors.primary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.registerTitle,
          style: AppTextStyles.h2.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.registerSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = [context.l10n.personalInformation, context.l10n.shopName, context.l10n.security];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isComplete = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isComplete || isActive
                            ? LinearGradient(
                                colors: isComplete
                                    ? [AppColors.success, Color(0xFF66BB6A)]
                                    : [AppColors.primary, AppColors.primaryLight],
                              )
                            : null,
                        color: !isActive ? AppColors.grey200 : null,
                        shape: BoxShape.circle,
                        boxShadow: isActive && !isComplete
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isComplete
                            ? const Icon(Icons.check,
                                size: 16, color: AppColors.white)
                            : Text(
                                '${i + 1}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isActive
                                      ? AppColors.white
                                      : AppColors.grey500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      overflow: TextOverflow.ellipsis,
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
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isComplete ? AppColors.success : AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPersonalInfoSection(bool isDark) {
    return _buildSectionCard(
      context.l10n.personalInformation,
      Icons.person,
      AppColors.primary,
      isDark,
      children: [
        CustomTextField(
          controller: _nameController,
          label: context.l10n.fullName,
          hint: context.l10n.fullNameHint,
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) => Validators.validateName(value, l10n: context.l10n),
          onChanged: (_) {
            _validateForm();
            if (_currentStep < 1 && _nameController.text.isNotEmpty) {
              setState(() => _currentStep = 1);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          controller: _phoneController,
          label: context.l10n.phoneNumber,
          hint: context.l10n.phoneHint,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: (value) => Validators.validatePhone(value, l10n: context.l10n),
          onChanged: (_) => _validateForm(),
        ),
      ],
    );
  }

  Widget _buildShopInfoSection(bool isDark) {
    return _buildSectionCard(
      context.l10n.shopDetails,
      Icons.store,
      AppColors.secondary,
      isDark,
      children: [
        CustomTextField(
          controller: _shopNameController,
          label: context.l10n.shopName,
          hint: context.l10n.shopNameHint,
          prefixIcon: Icons.storefront_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              Validators.validateRequired(value, fieldName: 'Shop name', l10n: context.l10n),
          onChanged: (_) {
            _validateForm();
            if (_currentStep < 2 && _shopNameController.text.isNotEmpty) {
              setState(() => _currentStep = 2);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.businessType, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _businessTypes.map((type) {
            final isSelected = _selectedBusinessType == type['name'];
            return AnimatedScaleOnTap(
              onTap: () {
                setState(() => _selectedBusinessType = type['name'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryLight],
                        )
                      : null,
                  color: !isSelected
                      ? AppColors.secondary.withValues(alpha: 0.06)
                      : null,
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
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type['name'] as String,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.secondary,
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

  Widget _buildSecuritySection(bool isDark) {
    return _buildSectionCard(
      context.l10n.security,
      Icons.lock,
      AppColors.success,
      isDark,
      children: [
        CustomTextField(
          controller: _passwordController,
          label: context.l10n.createPassword,
          hint: context.l10n.createPasswordHint,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.grey500,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) => Validators.validatePassword(value, l10n: context.l10n),
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          controller: _confirmPasswordController,
          label: context.l10n.confirmPassword,
          hint: context.l10n.confirmPasswordHint,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.grey500,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
            l10n: context.l10n,
          ),
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: 12),
        // Password strength indicator
        _buildPasswordStrength(),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color strengthColor;
    String strengthText;
    if (strength <= 1) {
      strengthColor = AppColors.error;
      strengthText = context.l10n.passwordStrengthWeak;
    } else if (strength <= 3) {
      strengthColor = AppColors.warning;
      strengthText = context.l10n.passwordStrengthMedium;
    } else {
      strengthColor = AppColors.success;
      strengthText = context.l10n.passwordStrengthStrong;
    }

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < strength ? strengthColor : AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '${context.l10n.passwordStrengthPrefix} $strengthText',
          style: AppTextStyles.caption.copyWith(color: strengthColor),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _agreedToTerms
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.grey200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _agreedToTerms,
              activeColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() => _agreedToTerms = val ?? false);
                _validateForm();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _agreedToTerms = !_agreedToTerms);
                _validateForm();
              },
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                  children: [
                    TextSpan(text: context.l10n.iAgreeToThe),
                    TextSpan(
                      text: context.l10n.termsAndConditions,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: context.l10n.andWord),
                    TextSpan(
                      text: context.l10n.privacyPolicy,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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

  Widget _buildRegisterButton() {
    final canSubmit = _isFormValid && !_isLoading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canSubmit ? 1.0 : 0.6,
      child: AnimatedScaleOnTap(
        onTap: canSubmit ? _onRegister : null,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.success, Color(0xFF66BB6A)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSubmit ? _onRegister : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.registerTitle,
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            context.l10n.alreadyHaveAccount,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            context.l10n.loginButton,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 12,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
