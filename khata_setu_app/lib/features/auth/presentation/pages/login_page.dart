import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../core/utils/app_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginRequested(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is AuthenticatedOffline) {
          context.go(RouteConstants.dashboard);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [context.surfaceColor, context.backgroundColor]
                    : [AppColors.primary.withOpacity(0.03), AppColors.white],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xl),

                          // Logo
                          AnimatedListItem(index: 0, child: _buildLogo()),
                          const SizedBox(height: AppSpacing.xl),

                          // Welcome text
                          AnimatedListItem(
                            index: 1,
                            child: _buildWelcomeText(isDark),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Login form card
                          AnimatedListItem(
                            index: 2,
                            child: _buildFormCard(isDark, isLoading),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Register link
                          AnimatedListItem(
                            index: 3,
                            child: _buildRegisterLink(),
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
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
          // Logo container
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      children: [
        Text(
          context.l10n.welcomeBack,
          style: AppTextStyles.h2.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.loginSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone Field
          CustomTextField(
            controller: _phoneController,
            label: context.l10n.phoneNumber,
            hint: context.l10n.phoneHint,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) =>
                Validators.validatePhone(value, l10n: context.l10n),
          ),
          const SizedBox(height: AppSpacing.md),

          // Password Field
          CustomTextField(
            controller: _passwordController,
            label: context.l10n.password,
            hint: context.l10n.passwordHint,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.l10n.passwordRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Remember me & Forgot password row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() => _rememberMe = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.rememberMe,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.comingSoon)),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(context.l10n.forgotPassword),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Login Button
          AnimatedScaleOnTap(
            onTap: isLoading ? null : _onLogin,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : _onLogin,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.login_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.loginButton,
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
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.dontHaveAccount,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
        ),
        TextButton(
          onPressed: () => context.push(RouteConstants.register),
          child: Text(
            context.l10n.registerNow,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
