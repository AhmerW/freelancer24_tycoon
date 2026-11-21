import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';

/// White text with a dark outline and drop shadow: the classic mobile-game
/// title look.
class StrokeText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color strokeColor;
  final double? strokeWidth;
  final TextAlign? textAlign;
  final int? maxLines;

  const StrokeText(
    this.text, {
    super.key,
    this.size = 18,
    this.color = Colors.white,
    this.strokeColor = GameColors.ink,
    this.strokeWidth,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final width = strokeWidth ?? (size / 6).clamp(2.0, 6.0);
    final style = GameFonts.display(size: size, color: color, height: 1.15);
    return Stack(
      children: [
        // Drop shadow + outline.
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
            shadows: [
              Shadow(
                color: strokeColor,
                offset: Offset(0, width * 0.7),
              ),
            ],
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: style,
        ),
      ],
    );
  }
}
