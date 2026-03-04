import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// KhataSetu Design System — Balanced Premium Fintech
// 5-Level Surface Hierarchy · Layered Dark · Warm Light
// ═══════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ─── Primary Palette — Used sparingly: CTAs, active states, highlights ───
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color primarySurface = Color(0xFFF0EDFF); // Light mode tinted surface

  // ─── Secondary / Accent — Badges, tags, decorative only ───
  static const Color secondary = Color(0xFFFD79A8);
  static const Color secondaryLight = Color(0xFFFFB8D0);
  static const Color secondaryDark = Color(0xFFE84393);

  // ─── Teal Accent — Charts, secondary CTAs ───
  static const Color teal = Color(0xFF00CEC9);
  static const Color tealLight = Color(0xFF55EFC4);
  static const Color tealDark = Color(0xFF00B894);

  // ─── Status Colors ───
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFECA57);
  static const Color info = Color(0xFF74B9FF);

  // ─── Transaction Colors ───
  static const Color credit = Color(0xFFFF6B6B);   // Customer owes (udhar given)
  static const Color debit = Color(0xFF00B894);     // Payment received

  // ─── Neutral Palette ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF1F3F5);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFADB5BD);
  static const Color grey500 = Color(0xFF868E96);
  static const Color grey600 = Color(0xFF6C757D);
  static const Color grey700 = Color(0xFF495057);
  static const Color grey800 = Color(0xFF343A40);
  static const Color grey900 = Color(0xFF212529);

  // ═══════════════════════════════════════════════════════
  // 5-LEVEL SURFACE SYSTEM — Dark Theme (Layered Navy)
  // L0: Background   — Deepest, behind everything
  // L1: Base Surface  — Main scroll area fill
  // L2: Elevated Card — Cards, list tiles, chips
  // L3: Modal Sheet   — Bottom sheets, dialogs
  // L4: Floating Nav   — Top-level navigation overlay
  // ═══════════════════════════════════════════════════════

  // Dark: Layered navy with subtle blue undertone (not flat black)
  static const Color backgroundDark  = Color(0xFF0D1117);  // L0 — GitHub-dark inspired
  static const Color surfaceDark     = Color(0xFF161B22);  // L1 — Subtle lift
  static const Color cardDark        = Color(0xFF1C2128);  // L2 — Card elevation
  static const Color sheetDark       = Color(0xFF222830);  // L3 — Modal/sheet
  static const Color navDark         = Color(0xFF1C2128);  // L4 — Floating nav

  // Dark glass / overlay tints
  static const Color glassDark       = Color(0xFF21262D);  // Frosted overlay fill
  static const Color glassHighlight  = Color(0x0AFFFFFF);  // Subtle glass sheen

  // ═══════════════════════════════════════════════════════
  // 5-LEVEL SURFACE SYSTEM — Light Theme (Warm Neutrals)
  // ═══════════════════════════════════════════════════════

  // Light: Warm off-white with soft grey layering
  static const Color backgroundLight = Color(0xFFF6F7FB);  // L0 — Warm off-white
  static const Color surfaceLight    = Color(0xFFFFFFFF);  // L1 — Pure white scroll area
  static const Color cardLight       = Color(0xFFFFFFFF);  // L2 — White card with shadow
  static const Color sheetLight      = Color(0xFFFFFFFF);  // L3 — Sheet
  static const Color navLight        = Color(0xFFFDFDFF);  // L4 — Slightly tinted nav

  // Light glass / overlay tints
  static const Color glassLight      = Color(0xFFF0F1F5);  // Subtle fill for chips/tags
  static const Color glassHighlightLight = Color(0x08000000); // Subtle inset

  // ─── Text Colors — Proper hierarchy for readability ───
  static const Color textPrimaryDark    = Color(0xFFE6EDF3);  // High contrast on dark
  static const Color textSecondaryDark  = Color(0xFF848D97);  // Muted, readable
  static const Color textTertiaryDark   = Color(0xFF5A6370);  // Lowest emphasis

  static const Color textPrimaryLight   = Color(0xFF1F2328);  // Near-black, high readability
  static const Color textSecondaryLight = Color(0xFF656D76);  // Medium emphasis
  static const Color textTertiaryLight  = Color(0xFF8B949E);  // Lowest emphasis

  // ─── Border / Divider Colors ───
  static const Color borderDark     = Color(0xFF30363D);  // Subtle, visible borders
  static const Color borderLight    = Color(0xFFD8DEE4);  // Soft light borders

  static const Color glassBorderDark  = Color(0xFF30363D);  // Glass card border (dark)
  static const Color glassBorderLight = Color(0xFFE1E4E8);  // Glass card border (light)

  // Legacy aliases (backward compat in premium_animations.dart)
  static const Color neonCyan = teal;
  static const Color neonBlue = Color(0xFF0984E3);
  static const Color neonPurple = Color(0xFFA855F7);
}

// ═══════════════════════════════════════════════════════════════════
// Gradient Definitions — Refined & Purposeful
// ═══════════════════════════════════════════════════════════════════

class AppGradients {
  AppGradients._();

  // ─── Primary — CTAs, active indicators only ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Status Gradients ───
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFECA57), Color(0xFFFF9F43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glass Card Gradients — Very subtle frosted tint ───
  static LinearGradient get glassGradientDark => LinearGradient(
    colors: [
      const Color(0xFFFFFFFF).withValues(alpha: 0.03),
      const Color(0xFFFFFFFF).withValues(alpha: 0.01),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get glassGradientLight => LinearGradient(
    colors: [
      const Color(0xFFFFFFFF).withValues(alpha: 0.90),
      const Color(0xFFFFFFFF).withValues(alpha: 0.75),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Ambient Background Glows — Much softer, less purple ───
  static const RadialGradient backgroundGlowPurple = RadialGradient(
    center: Alignment(-0.8, -0.6),
    radius: 1.4,
    colors: [Color(0x186C5CE7), Color(0x00000000)],  // Was 0x40, now 0x18
  );

  static const RadialGradient backgroundGlowCyan = RadialGradient(
    center: Alignment(0.8, 0.6),
    radius: 1.2,
    colors: [Color(0x0C00CEC9), Color(0x00000000)],  // Was 0x20, now 0x0C
  );

  static const RadialGradient backgroundGlowPink = RadialGradient(
    center: Alignment(0.3, -0.8),
    radius: 0.9,
    colors: [Color(0x0CFD79A8), Color(0x00000000)],  // Was 0x20, now 0x0C
  );

  // ─── Light Theme Ambient Glows — Very soft warm tints ───
  static const RadialGradient backgroundGlowLightPurple = RadialGradient(
    center: Alignment(-0.7, -0.5),
    radius: 1.4,
    colors: [Color(0x0A6C5CE7), Color(0x00000000)],
  );

  static const RadialGradient backgroundGlowLightBlue = RadialGradient(
    center: Alignment(0.7, 0.5),
    radius: 1.2,
    colors: [Color(0x0874B9FF), Color(0x00000000)],
  );

  // ─── Trust Score Gradients ───
  static const LinearGradient trustExcellent = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
  );
  static const LinearGradient trustGood = LinearGradient(
    colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
  );
  static const LinearGradient trustAverage = LinearGradient(
    colors: [Color(0xFFFECA57), Color(0xFFFF9F43)],
  );
  static const LinearGradient trustPoor = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFD79A8)],
  );

  // ─── Shimmer ───
  static const LinearGradient shimmerDark = LinearGradient(
    colors: [Color(0xFF1C2128), Color(0xFF252C35), Color(0xFF1C2128)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.5, 0),
    end: Alignment(1.5, 0),
  );

  static const LinearGradient shimmerLight = LinearGradient(
    colors: [Color(0xFFECEDF1), Color(0xFFF5F6F8), Color(0xFFECEDF1)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.5, 0),
    end: Alignment(1.5, 0),
  );

  // ─── Surface Depth Overlay — Subtle gradient on elevated surfaces ───
  static LinearGradient get surfaceOverlayDark => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFFFFFFFF).withValues(alpha: 0.02),
      const Color(0xFFFFFFFF).withValues(alpha: 0.00),
    ],
  );

  static LinearGradient get surfaceOverlayLight => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFFFFFFFF).withValues(alpha: 0.6),
      const Color(0xFFFFFFFF).withValues(alpha: 0.3),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// Spacing & Radius Constants
// ═══════════════════════════════════════════════════════════════════

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Standard bottom padding to clear floating nav bar
  static const double navClearance = 100.0;
}

class AppRadius {
  AppRadius._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;    // Was 24, slightly tighter
  static const double xxl = 28.0;   // Was 32
  static const double circular = 100.0;
}

// ═══════════════════════════════════════════════════════════════════
// Typography System — Refined scaling
// ═══════════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();
  static const String fontFamily = 'Poppins';

  // ─── Display ───
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w800,
    height: 1.1, letterSpacing: -1.2,
  );

  // ─── Headings ───
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.bold,
    height: 1.2, letterSpacing: -0.8,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.bold,
    height: 1.25, letterSpacing: -0.4,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600,
    height: 1.3, letterSpacing: -0.2,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // ─── Body ───
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.normal, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.normal, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.normal, height: 1.5,
  );

  // ─── Labels ───
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    height: 1.4, letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w500,
    height: 1.4, letterSpacing: 0.3,
  );

  // ─── Button ───
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.3, height: 1.4,
  );

  // ─── Caption ───
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.normal,
    height: 1.4, letterSpacing: 0.2,
  );
}
