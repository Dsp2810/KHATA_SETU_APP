import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
// KhataSetu Premium Animations — Fintech Grade
// ═══════════════════════════════════════════════════════════════════

/// Animated Trust Score Ring — CustomPainter with gradient arc
class TrustScoreRing extends StatefulWidget {
  final double score; // 0-100
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;
  final Duration duration;
  final Widget? center;

  const TrustScoreRing({
    super.key,
    required this.score,
    this.size = 60,
    this.strokeWidth = 4,
    this.textStyle,
    this.duration = const Duration(milliseconds: 1200),
    this.center,
  });

  @override
  State<TrustScoreRing> createState() => _TrustScoreRingState();
}

class _TrustScoreRingState extends State<TrustScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(TrustScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score / 100)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.neonCyan;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value * 100;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _TrustRingPainter(
              progress: _animation.value,
              scoreColor: _getScoreColor(currentScore),
              strokeWidth: widget.strokeWidth,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Center(
              child: widget.center ?? Text(
                '${currentScore.toInt()}',
                style: widget.textStyle ?? TextStyle(
                  fontSize: widget.size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: _getScoreColor(currentScore),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  final double progress;
  final Color scoreColor;
  final double strokeWidth;
  final bool isDark;

  _TrustRingPainter({
    required this.progress,
    required this.scoreColor,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: [scoreColor.withOpacity(0.3), scoreColor],
      stops: const [0.0, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);

    // Glow dot at the end
    final endAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);

    final glowPaint = Paint()
      ..color = scoreColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.8, glowPaint);

    final dotPaint = Paint()..color = scoreColor;
    canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.5, dotPaint);
  }

  @override
  bool shouldRepaint(_TrustRingPainter oldDelegate) =>
      progress != oldDelegate.progress || scoreColor != oldDelegate.scoreColor;
}

/// Morphing Gradient Button — animated shape + glow
class MorphingGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;

  const MorphingGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradient = AppGradients.primaryGradient,
    this.icon,
    this.isLoading = false,
    this.height = 56,
    this.width,
  });

  @override
  State<MorphingGradientButton> createState() => _MorphingGradientButtonState();
}

class _MorphingGradientButtonState extends State<MorphingGradientButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnim, _glowAnim]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) {
              _pressController.reverse();
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
            onTapCancel: () => _pressController.reverse(),
            child: Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient as LinearGradient)
                        .colors
                        .first
                        .withOpacity(_glowAnim.value),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glass Shimmer — Premium shimmer for glass surfaces
class GlassShimmer extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;

  const GlassShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<GlassShimmer> createState() => _GlassShimmerState();
}

class _GlassShimmerState extends State<GlassShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isLoading) _controller.repeat();
  }

  @override
  void didUpdateWidget(GlassShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? [
                      AppColors.glassDark,
                      AppColors.glassDark.withOpacity(0.5),
                      Colors.white.withOpacity(0.08),
                      AppColors.glassDark.withOpacity(0.5),
                      AppColors.glassDark,
                    ]
                  : [
                      AppColors.grey200,
                      AppColors.grey100,
                      Colors.white.withOpacity(0.6),
                      AppColors.grey100,
                      AppColors.grey200,
                    ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer Loading Card — placeholder for glass cards
class ShimmerGlassCard extends StatelessWidget {
  final double height;
  final double? width;

  const ShimmerGlassCard({super.key, this.height = 120, this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
      ),
    );
  }
}

/// Animated Gradient Border — pulsing neon border effect
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.xl,
    this.borderWidth = 2,
    this.gradient = AppGradients.primaryGradient,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            gradient: widget.gradient as LinearGradient,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double borderWidth;
  final LinearGradient gradient;

  _GradientBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final rotatedGradient = LinearGradient(
      colors: gradient.colors,
      stops: gradient.stops,
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final paint = Paint()
      ..shader = rotatedGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Spring Physics Animation Wrapper
class SpringContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const SpringContainer({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.95,
  });

  @override
  State<SpringContainer> createState() => _SpringContainerState();
}

class _SpringContainerState extends State<SpringContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animation = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  void _onTapUp(TapUpDetails details) {
    _animation = Tween<double>(
      begin: widget.pressScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const _SpringCurve(),
    ));
    _controller.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _animation = Tween<double>(
      begin: widget.pressScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    final dampedT = -math.exp(-6 * t) * math.cos(12 * t) + 1;
    return dampedT.clamp(0.0, 1.0);
  }
}

/// Confetti Celebration Overlay
class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    this.trigger = false,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pieces.clear();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _pieces.clear();
    for (int i = 0; i < 80; i++) {
      _pieces.add(_ConfettiPiece(
        x: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        wobble: _random.nextDouble() * 4,
        rotation: _random.nextDouble() * math.pi * 2,
        color: [
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.neonCyan,
          AppColors.secondary,
          AppColors.success,
          AppColors.warning,
          const Color(0xFFFFD700),
        ][_random.nextInt(7)],
        size: 4 + _random.nextDouble() * 6,
      ));
    }
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating && _pieces.isEmpty) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double speed;
  final double wobble;
  final double rotation;
  final Color color;
  final double size;

  _ConfettiPiece({
    required this.x,
    required this.speed,
    required this.wobble,
    required this.rotation,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final y = -50 + (size.height + 100) * progress * piece.speed;
      final x = piece.x * size.width +
          math.sin(progress * math.pi * piece.wobble) * 40;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = piece.color.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + progress * math.pi * 3);

      // Draw rectangle confetti
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Parallax Sliver Header Delegate
class GlassParallaxHeader extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget Function(BuildContext context, double shrinkOffset, bool overlapsContent) builder;

  GlassParallaxHeader({
    required this.maxHeight,
    required this.minHeight,
    required this.builder,
  });

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context, shrinkOffset, overlapsContent);
  }

  @override
  bool shouldRebuild(covariant GlassParallaxHeader oldDelegate) =>
      maxHeight != oldDelegate.maxHeight ||
      minHeight != oldDelegate.minHeight;
}

/// Fluid Bottom Nav Indicator
class FluidNavIndicator extends StatelessWidget {
  final Animation<double> animation;
  final int itemCount;
  final double indicatorWidth;
  final Gradient gradient;

  const FluidNavIndicator({
    super.key,
    required this.animation,
    required this.itemCount,
    this.indicatorWidth = 48,
    this.gradient = AppGradients.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final sectionWidth = totalWidth / itemCount;
            final centerX = sectionWidth * animation.value + sectionWidth / 2;

            return CustomPaint(
              size: Size(totalWidth, 4),
              painter: _FluidIndicatorPainter(
                centerX: centerX,
                width: indicatorWidth,
                gradient: gradient,
              ),
            );
          },
        );
      },
    );
  }
}

class _FluidIndicatorPainter extends CustomPainter {
  final double centerX;
  final double width;
  final Gradient gradient;

  _FluidIndicatorPainter({
    required this.centerX,
    required this.width,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(centerX, size.height / 2),
      width: width,
      height: size.height,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      glowPaint..color = glowPaint.color.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(_FluidIndicatorPainter oldDelegate) =>
      centerX != oldDelegate.centerX;
}

/// Counting Animation Widget with number formatting
class CountingText extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final bool formatAsCompact;

  const CountingText({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.formatAsCompact = false,
  });

  @override
  State<CountingText> createState() => _CountingTextState();
}

class _CountingTextState extends State<CountingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double val) {
    if (widget.formatAsCompact) {
      if (val >= 10000000) return '${(val / 10000000).toStringAsFixed(1)}Cr';
      if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
      if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    }
    if (val == val.toInt().toDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_format(_animation.value)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Empty State Widget — Polished
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;
  final Gradient? iconGradient;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glass circle with gradient icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.glassDark, AppColors.glassDark.withOpacity(0.5)]
                      : [AppColors.grey100, AppColors.grey50],
                ),
                border: Border.all(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 32,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => (iconGradient ?? AppGradients.primaryGradient)
                    .createShader(bounds),
                child: Icon(icon, size: 40),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              MorphingGradientButton(
                label: buttonLabel!,
                onTap: onAction,
                width: 200,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient Icon Box — small gradient-filled icon container
class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;
  final double iconSize;
  final double borderRadius;

  const GradientIconBox({
    super.key,
    required this.icon,
    this.gradient = AppGradients.primaryGradient,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// Status Dot — animated pulsing status indicator
class StatusDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool pulse;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.pulse = false,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.pulse ? 1.0 + _controller.value * 0.5 : 1.0;
        final opacity = widget.pulse ? 1.0 - _controller.value * 0.4 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4 * opacity),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
