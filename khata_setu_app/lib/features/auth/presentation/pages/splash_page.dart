import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatter.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/biometric_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _loadingFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Sequence animations
    _logoController.forward().then((_) {
      _textController.forward();
      _pulseController.repeat(reverse: true);
      _particleController.repeat();
    });

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check auth status via the global AuthBloc
    final authBloc = context.read<AuthBloc>();
    authBloc.add(const CheckAuthStatus());
    await authBloc.stream.firstWhere(
      (s) => s is Authenticated || s is AuthenticatedOffline || s is Unauthenticated || s is AuthError,
    );

    if (!mounted) return;

    final state = authBloc.state;
    if (state is Authenticated || state is AuthenticatedOffline) {
      // Check biometric requirement
      final biometricCubit = context.read<BiometricCubit>();
      final shouldBiometric = await biometricCubit.shouldRequireBiometric();

      if (!mounted) return;

      if (shouldBiometric) {
        final l10n = context.l10n;
        try {
          final authenticated = await biometricCubit.authenticate(
            localizedReason: l10n.biometricAuthReason,
          );

          if (!mounted) return;

          if (authenticated) {
            context.go(RouteConstants.dashboard);
          } else {
            // Biometric failed or cancelled → fall back to login
            context.go(RouteConstants.login);
          }
        } catch (e) {
          // Any error during biometric → go to login
          debugPrint('Biometric auth error in splash: $e');
          if (mounted) context.go(RouteConstants.login);
        }
      } else {
        context.go(RouteConstants.dashboard);
      }
    } else {
      context.go(RouteConstants.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              AppColors.primary,
              Color(0xFF42A5F5),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles
            ...List.generate(8, (i) => _buildFloatingParticle(i)),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotate.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Decorative ring
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Logo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App name
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, _) {
                      return Column(
                        children: [
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Text(
                                context.l10n.appName,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  context.l10n.splashTagline,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    color: AppColors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          FadeTransition(
                            opacity: _loadingFade,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: const LinearProgressIndicator(
                                      minHeight: 3,
                                      backgroundColor: Color(0x40FFFFFF),
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.loadingYourShop,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Version at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _loadingFade,
                    child: child,
                  );
                },
                child: Text(
                  context.l10n.appVersion(AppConstants.appVersion),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index * 42);
    final size = 4.0 + random.nextDouble() * 8;
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final endY = startY - 0.2 - random.nextDouble() * 0.3;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final screenSize = MediaQuery.of(context).size;
        final progress = (_particleController.value + index * 0.125) % 1.0;
        final currentY = startY + (endY - startY) * progress;
        final opacity = (1.0 - progress).clamp(0.0, 0.4);

        return Positioned(
          left: startX * screenSize.width,
          top: currentY * screenSize.height,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
