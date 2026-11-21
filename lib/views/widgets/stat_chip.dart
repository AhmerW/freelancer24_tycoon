import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

/// Small chunky pill: icon + value, e.g. "⏱ 2m 30s".
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String? tooltip;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF3B5BA0);
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: GameColors.panelShade, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: GameFonts.display(size: 15, color: GameColors.ink)),
        ],
      ),
    );
    return tooltip == null
        ? chip
        : Tooltip(
            message: tooltip!,
            triggerMode: TooltipTriggerMode.tap,
            child: chip);
  }
}

/// Centered message for empty lists, on the blue game background.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.85))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: 0,
                    end: -6,
                    duration: 1200.ms,
                    curve: Curves.easeInOut),
            const SizedBox(height: 12),
            StrokeText(message, size: 18, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
