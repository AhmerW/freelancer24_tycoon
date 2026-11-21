import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

/// A light card with a thick outline and a solid drop "lip", like a game UI
/// panel.
class GamePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final Color? borderColor;
  final double borderWidth;

  /// Optional colored header with outlined title.
  final String? title;
  final GameTone? titleTone;
  final Widget? titleTrailing;

  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.color = GameColors.panel,
    this.borderColor,
    this.borderWidth = 3,
    this.title,
    this.titleTone,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? GameColors.panelBorder;
    final radius = BorderRadius.circular(18);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: [
          BoxShadow(color: border, offset: const Offset(0, 4)),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (titleTone ?? GameTone.blue).top,
                      (titleTone ?? GameTone.blue).bottom,
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: border, width: 2)),
                ),
                child: Row(
                  children: [
                    Expanded(child: StrokeText(title!, size: 20, maxLines: 1)),
                    if (titleTrailing != null) titleTrailing!,
                  ],
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A rounded square with a glossy gradient holding an icon or image.
class IconBadge extends StatelessWidget {
  final Widget child;
  final GameTone tone;
  final double size;

  const IconBadge({
    super.key,
    required this.child,
    this.tone = GameTone.blue,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.top, tone.bottom],
        ),
        border: Border.all(color: GameColors.ink, width: 2),
        boxShadow: [BoxShadow(color: tone.lip, offset: const Offset(0, 3))],
      ),
      child: Center(child: child),
    );
  }
}

/// Round coin icon for money.
class CoinIcon extends StatelessWidget {
  final double size;

  const CoinIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF1A8), GameColors.gold, GameColors.goldDark],
          stops: [0, 0.55, 1],
        ),
        border: Border.all(color: const Color(0xFF7A4E00), width: size * 0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        '\$',
        style: GameFonts.display(
            size: size * 0.62, color: const Color(0xFF8A5A00), height: 1),
      ),
    );
  }
}

/// Chunky rounded progress bar with an outline and a glossy fill.
class GameProgressBar extends StatelessWidget {
  final double value;
  final GameTone tone;
  final double height;
  final String? label;

  const GameProgressBar({
    super.key,
    required this.value,
    this.tone = GameTone.green,
    this.height = 18,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: GameColors.ink.withValues(alpha: 0.75),
        borderRadius: radius,
        border: Border.all(color: GameColors.ink, width: 2),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tone.top, tone.bottom],
                  ),
                ),
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                  height: height * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
            if (label != null)
              Center(child: StrokeText(label!, size: height * 0.62)),
          ],
        ),
      ),
    );
  }
}

/// Counts smoothly to [value] whenever it changes.
class RollingNumber extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final Widget Function(String text) builder;

  const RollingNumber({
    super.key,
    required this.value,
    required this.format,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(format(v)),
    );
  }
}

/// Slowly drifting diagonal pattern on a blue gradient: the game backdrop.
class GameBackground extends StatefulWidget {
  final Widget child;
  final Color? top;
  final Color? bottom;

  const GameBackground({super.key, required this.child, this.top, this.bottom});

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.top ?? GameColors.bgTop,
            widget.bottom ?? GameColors.bgBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) =>
                    CustomPaint(painter: _PatternPainter(_c.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final double t;

  _PatternPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 56.0;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final shift = t * spacing * 2;
    canvas.save();
    canvas.rotate(-math.pi / 12);
    for (var y = -spacing * 2; y < size.height + spacing * 4; y += spacing) {
      for (var x = -spacing * 4; x < size.width + spacing * 4; x += spacing) {
        final dx = x +
            shift % (spacing * 2) +
            ((y ~/ spacing).isEven ? 0 : spacing / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(dx, y), width: 18, height: 18),
            const Radius.circular(5),
          ),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.t != t;
}
