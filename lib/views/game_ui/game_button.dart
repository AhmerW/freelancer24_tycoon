import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

/// Chunky 3D button: glossy gradient on a darker "lip" that squashes when
/// pressed, with a haptic tick.
class GameButton extends StatefulWidget {
  final GameTone tone;
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final double height;
  final double? width;
  final double fontSize;

  /// Adds a slow shine sweep, to draw the eye (e.g. something affordable).
  final bool shine;

  const GameButton({
    super.key,
    this.tone = GameTone.green,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.height = 48,
    this.width,
    this.fontSize = 18,
    this.shine = false,
  }) : assert(label != null || child != null || icon != null);

  const GameButton.small({
    super.key,
    this.tone = GameTone.green,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.width,
    this.shine = false,
  })  : height = 36,
        fontSize = 15,
        assert(label != null || child != null || icon != null);

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool down) {
    if (_enabled && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final tone = _enabled ? widget.tone : GameTone.grey;
    final lip = (widget.height * 0.12).clamp(3.0, 6.0);
    final radius = BorderRadius.circular(widget.height * 0.32);

    Widget content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Icon(widget.icon,
                  color: Colors.white,
                  size: widget.fontSize + 4,
                  shadows: const [
                    Shadow(color: GameColors.ink, offset: Offset(0, 2))
                  ]),
            if (widget.icon != null && widget.label != null)
              const SizedBox(width: 6),
            if (widget.label != null)
              Flexible(
                child: StrokeText(widget.label!,
                    size: widget.fontSize,
                    maxLines: 1,
                    textAlign: TextAlign.center),
              ),
          ],
        );

    Widget face = Container(
      height: widget.height - lip,
      padding: EdgeInsets.symmetric(
          horizontal: (widget.width ?? 999) < 64 ? 0 : widget.height * 0.3),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone.top, tone.bottom],
        ),
        border:
            Border.all(color: GameColors.ink.withValues(alpha: 0.85), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glossy highlight on the top half.
          Positioned(
            top: 3,
            left: 2,
            right: 2,
            height: (widget.height - lip) * 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ),
          Center(child: content),
        ],
      ),
    );
    if (widget.shine && _enabled) {
      face = face.animate(onPlay: (c) => c.repeat()).shimmer(
          delay: 1800.ms,
          duration: 900.ms,
          color: Colors.white.withValues(alpha: 0.55));
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                Sfx.instance.play(Sound.tap);
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 80),
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: Stack(
              // The face sizes the button: full width when constrained,
              // its content's width otherwise.
              fit: StackFit.passthrough,
              children: [
                // The lip (3D side of the button).
                Positioned.fill(
                  top: lip,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: tone.lip,
                      border: Border.all(
                          color: GameColors.ink.withValues(alpha: 0.85),
                          width: 2),
                    ),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 60),
                  padding: EdgeInsets.only(
                      top: _down ? lip : 0, bottom: _down ? 0 : lip),
                  child: face,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps any widget with a bouncy press effect.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              Sfx.instance.play(Sound.click, volume: 0.8);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
