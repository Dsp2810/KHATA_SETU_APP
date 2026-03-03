import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
// KhataSetu Theme — Balanced Premium Fintech
// 5-level surface · Layered dark · Warm light · Animated switching
// ═══════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTextStyles.fontFamily,

    // Core Material colors
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primarySurface,
      secondary: AppColors.teal,
      secondaryContainer: Color(0xFFE0FAF8),
      tertiary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: AppColors.white,
      outline: AppColors.borderLight,
    ),

    scaffoldBackgroundColor: AppColors.backgroundLight,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20, fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    ),

    // Bottom Nav — hidden (using custom floating nav)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey500,
      elevation: 0,
    ),

    // Cards — Soft shadow, no border
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      margin: EdgeInsets.zero,
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.button,
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryLight),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.sheetLight,
      modalBarrierColor: Color(0x40000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.sheetLight,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.glassLight,
      selectedColor: AppColors.primarySurface,
      side: BorderSide(color: AppColors.borderLight.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.circular)),
      labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryLight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.grey800,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      behavior: SnackBarBehavior.floating,
    ),

    // Extensions
    extensions: [
      _lightKhataTheme,
    ],
  );

  // ─────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTextStyles.fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      primaryContainer: Color(0xFF2A2550),
      secondary: AppColors.teal,
      secondaryContainer: Color(0xFF0A3634),
      tertiary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: AppColors.black,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: AppColors.white,
      outline: AppColors.borderDark,
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20, fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textTertiaryDark,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      margin: EdgeInsets.zero,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: AppTextStyles.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.sheetDark,
      modalBarrierColor: Color(0x80000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.sheetDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.glassDark,
      selectedColor: const Color(0xFF2A2550),
      side: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.circular)),
      labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardDark,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      behavior: SnackBarBehavior.floating,
    ),

    extensions: [
      _darkKhataTheme,
    ],
  );

  // ─────────────────────────────────────────────
  // Theme Extensions — 5-level surface + semantic tokens
  // ─────────────────────────────────────────────
  static final KhataThemeExtension _lightKhataTheme = KhataThemeExtension(
    isDark: false,
    // 5-Level Surface System
    backgroundColor: AppColors.backgroundLight,
    surfaceColor: AppColors.surfaceLight,
    cardColor: AppColors.cardLight,
    sheetColor: AppColors.sheetLight,
    navColor: AppColors.navLight,
    glassColor: AppColors.glassLight,
    // Text
    textPrimaryColor: AppColors.textPrimaryLight,
    textSecondaryColor: AppColors.textSecondaryLight,
    textTertiaryColor: AppColors.textTertiaryLight,
    // Border
    dividerColor: AppColors.borderLight,
    glassBorderColor: AppColors.glassBorderLight,
    // Inputs
    inputFillColor: AppColors.glassLight,
    // Status
    successColor: AppColors.success,
    errorColor: AppColors.error,
    warningColor: AppColors.warning,
    infoColor: AppColors.info,
    // Elevation
    cardShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
      BoxShadow(color: Color(0x06000000), blurRadius: 30, offset: Offset(0, 8)),
    ],
    sheetShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4)),
      BoxShadow(color: Color(0x08000000), blurRadius: 48, offset: Offset(0, -12)),
    ],
    navShadow: const [
      BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, -2)),
      BoxShadow(color: Color(0x06000000), blurRadius: 32, offset: Offset(0, -6)),
    ],
    // Glass
    glassGradient: AppGradients.glassGradientLight,
    glassBlur: 0, // No blur in light mode — clean elevated cards
  );

  static final KhataThemeExtension _darkKhataTheme = KhataThemeExtension(
    isDark: true,
    // 5-Level Surface System
    backgroundColor: AppColors.backgroundDark,
    surfaceColor: AppColors.surfaceDark,
    cardColor: AppColors.cardDark,
    sheetColor: AppColors.sheetDark,
    navColor: AppColors.navDark,
    glassColor: AppColors.glassDark,
    // Text
    textPrimaryColor: AppColors.textPrimaryDark,
    textSecondaryColor: AppColors.textSecondaryDark,
    textTertiaryColor: AppColors.textTertiaryDark,
    // Border
    dividerColor: AppColors.borderDark,
    glassBorderColor: AppColors.glassBorderDark,
    // Inputs
    inputFillColor: AppColors.glassDark,
    // Status
    successColor: AppColors.success,
    errorColor: AppColors.error,
    warningColor: AppColors.warning,
    infoColor: AppColors.info,
    // Elevation — Dark mode uses subtle border instead of shadow
    cardShadow: const [],
    sheetShadow: const [
      BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, -8)),
    ],
    navShadow: const [
      BoxShadow(color: Color(0x30000000), blurRadius: 24, offset: Offset(0, -4)),
    ],
    // Glass
    glassGradient: AppGradients.glassGradientDark,
    glassBlur: 20, // Frosted glass in dark mode
  );
}

// ═══════════════════════════════════════════════════════════════════
// KhataThemeExtension — The single source of truth for UI queries
// ═══════════════════════════════════════════════════════════════════

@immutable
class KhataThemeExtension extends ThemeExtension<KhataThemeExtension> {
  final bool isDark;
  // 5-level surfaces
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color sheetColor;
  final Color navColor;
  final Color glassColor;
  // Text
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color textTertiaryColor;
  // Border
  final Color dividerColor;
  final Color glassBorderColor;
  // Input
  final Color inputFillColor;
  // Status
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color infoColor;
  // Shadows
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> sheetShadow;
  final List<BoxShadow> navShadow;
  // Glass
  final LinearGradient glassGradient;
  final double glassBlur;

  const KhataThemeExtension({
    required this.isDark,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.sheetColor,
    required this.navColor,
    required this.glassColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.textTertiaryColor,
    required this.dividerColor,
    required this.glassBorderColor,
    required this.inputFillColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.infoColor,
    required this.cardShadow,
    required this.sheetShadow,
    required this.navShadow,
    required this.glassGradient,
    required this.glassBlur,
  });

  @override
  KhataThemeExtension copyWith({
    bool? isDark,
    Color? backgroundColor, Color? surfaceColor, Color? cardColor,
    Color? sheetColor, Color? navColor, Color? glassColor,
    Color? textPrimaryColor, Color? textSecondaryColor, Color? textTertiaryColor,
    Color? dividerColor, Color? glassBorderColor, Color? inputFillColor,
    Color? successColor, Color? errorColor, Color? warningColor, Color? infoColor,
    List<BoxShadow>? cardShadow, List<BoxShadow>? sheetShadow, List<BoxShadow>? navShadow,
    LinearGradient? glassGradient, double? glassBlur,
  }) {
    return KhataThemeExtension(
      isDark: isDark ?? this.isDark,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      sheetColor: sheetColor ?? this.sheetColor,
      navColor: navColor ?? this.navColor,
      glassColor: glassColor ?? this.glassColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textTertiaryColor: textTertiaryColor ?? this.textTertiaryColor,
      dividerColor: dividerColor ?? this.dividerColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
      inputFillColor: inputFillColor ?? this.inputFillColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      cardShadow: cardShadow ?? this.cardShadow,
      sheetShadow: sheetShadow ?? this.sheetShadow,
      navShadow: navShadow ?? this.navShadow,
      glassGradient: glassGradient ?? this.glassGradient,
      glassBlur: glassBlur ?? this.glassBlur,
    );
  }

  @override
  KhataThemeExtension lerp(covariant KhataThemeExtension? other, double t) {
    if (other == null) return this;
    return KhataThemeExtension(
      isDark: t < 0.5 ? isDark : other.isDark,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      sheetColor: Color.lerp(sheetColor, other.sheetColor, t)!,
      navColor: Color.lerp(navColor, other.navColor, t)!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      textPrimaryColor: Color.lerp(textPrimaryColor, other.textPrimaryColor, t)!,
      textSecondaryColor: Color.lerp(textSecondaryColor, other.textSecondaryColor, t)!,
      textTertiaryColor: Color.lerp(textTertiaryColor, other.textTertiaryColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      glassBorderColor: Color.lerp(glassBorderColor, other.glassBorderColor, t)!,
      inputFillColor: Color.lerp(inputFillColor, other.inputFillColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      sheetShadow: t < 0.5 ? sheetShadow : other.sheetShadow,
      navShadow: t < 0.5 ? navShadow : other.navShadow,
      glassGradient: LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BuildContext Extensions — Keep backward-compatible API surface
// ═══════════════════════════════════════════════════════════════════

extension KhataThemeX on BuildContext {
  KhataThemeExtension get _ext =>
      Theme.of(this).extension<KhataThemeExtension>()!;

  // Theme mode
  bool get isDark => _ext.isDark;

  // 5-Level Surfaces
  Color get backgroundColor => _ext.backgroundColor;
  Color get surfaceColor => _ext.surfaceColor;
  Color get cardColor => _ext.cardColor;
  Color get sheetColor => _ext.sheetColor;
  Color get navColor => _ext.navColor;
  Color get glassColor => _ext.glassColor;

  // Text
  Color get textPrimaryColor => _ext.textPrimaryColor;
  Color get textSecondaryColor => _ext.textSecondaryColor;
  Color get textTertiaryColor => _ext.textTertiaryColor;

  // Border
  Color get dividerColor => _ext.dividerColor;
  Color get glassBorderColor => _ext.glassBorderColor;

  // Input
  Color get inputFillColor => _ext.inputFillColor;

  // Status
  Color get successColor => _ext.successColor;
  Color get errorColor => _ext.errorColor;
  Color get warningColor => _ext.warningColor;
  Color get infoColor => _ext.infoColor;

  // Shadows by level
  List<BoxShadow> get cardShadow => _ext.cardShadow;
  List<BoxShadow> get sheetShadow => _ext.sheetShadow;
  List<BoxShadow> get navShadow => _ext.navShadow;

  // Glass
  LinearGradient get glassGradient => _ext.glassGradient;
  double get glassBlur => _ext.glassBlur;
}

// ═══════════════════════════════════════════════════════════════════
// SurfaceCard — Replaces GlassCard with theme-adaptive elevation
// Soft shadow on light, subtle glass on dark, unified API
// ═══════════════════════════════════════════════════════════════════

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final bool useGlass; // force glass style even in light mode
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.gradient,
    this.useGlass = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveColor = color ?? context.cardColor;
    final useFrost = useGlass || isDark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient != null ? null : (useFrost ? effectiveColor.withOpacity(isDark ? 0.65 : 0.9) : effectiveColor),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : (isDark ? Border.all(color: context.glassBorderColor.withOpacity(0.4)) : null),
        boxShadow: isDark ? null : context.cardShadow,
        gradient: gradient ?? (useFrost ? context.glassGradient : null),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    // Frosted glass effect only in dark mode
    if (useFrost && isDark && context.glassBlur > 0) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: context.glassBlur,
            sigmaY: context.glassBlur,
          ),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

// Backward compat alias
typedef GlassCard = SurfaceCard;

// ═══════════════════════════════════════════════════════════════════
// AmbientBackground — Subtle ambient glows (drastically toned down)
// ═══════════════════════════════════════════════════════════════════

class AmbientBackground extends StatelessWidget {
  final Widget child;
  final bool showGlows;

  const AmbientBackground({
    super.key,
    required this.child,
    this.showGlows = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (!showGlows) {
      return Container(
        color: context.backgroundColor,
        child: child,
      );
    }

    return Container(
      color: context.backgroundColor,
      child: Stack(
        children: [
          // Ambient glows — very subtle
          if (isDark) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppGradients.backgroundGlowPurple,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppGradients.backgroundGlowCyan,
                ),
              ),
            ),
          ] else ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppGradients.backgroundGlowLightPurple,
                ),
              ),
            ),
          ],
          // Content
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GradientText — Accent text with gradient shader
// ═══════════════════════════════════════════════════════════════════

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => (gradient ?? AppGradients.primaryGradient)
          .createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GradientBadge — Small gradient pill for status/tag
// ═══════════════════════════════════════════════════════════════════

class GradientBadge extends StatelessWidget {
  final String label;
  final Gradient? gradient;
  final Color? textColor;
  final double? fontSize;

  const GradientBadge({
    super.key,
    required this.label,
    this.gradient,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor ?? AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// showGlassBottomSheet — Theme-adaptive bottom sheet that floats
// above navigation with proper elevation separation.
// ═══════════════════════════════════════════════════════════════════

Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
}) {
  final isDark = context.isDark;

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: isDark ? const Color(0x80000000) : const Color(0x30000000),
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: AppSpacing.navClearance + 8, // Float above nav bar
        ),
        decoration: BoxDecoration(
          color: ctx.sheetColor.withOpacity(isDark ? 0.92 : 1.0),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: isDark
              ? Border.all(color: ctx.glassBorderColor.withOpacity(0.4))
              : null,
          boxShadow: ctx.sheetShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: isDark
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: builder(ctx),
                ),
              )
            : builder(ctx),
      );
    },
  );
}
