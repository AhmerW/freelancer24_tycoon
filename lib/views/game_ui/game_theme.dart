import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors and fonts of the game look: bright, chunky and outlined.
abstract final class GameColors {
  // Background
  static const bgTop = Color(0xFF2F7FE0);
  static const bgBottom = Color(0xFF173E8C);

  // Panels
  static const panel = Color(0xFFF2F6FF);
  static const panelShade = Color(0xFFD5E1F7);
  static const panelBorder = Color(0xFF1B3366);
  static const ink = Color(0xFF1B2A4A);

  // HUD
  static const hud = Color(0xCC0E2350);
  static const gold = Color(0xFFFFC93C);
  static const goldDark = Color(0xFFC98A00);
  static const energy = Color(0xFFB66DFF);
  static const energyDark = Color(0xFF6A2DB8);

  // Feedback
  static const good = Color(0xFF4CC93A);
  static const bad = Color(0xFFE8473E);
  static const vip = Color(0xFFFFB300);
}

/// A three-tone color set for chunky elements (buttons, badges, ribbons).
class GameTone {
  final Color top;
  final Color bottom;
  final Color lip;

  const GameTone(this.top, this.bottom, this.lip);

  static const green =
      GameTone(Color(0xFF8BE55B), Color(0xFF45B52E), Color(0xFF2B7A1C));
  static const yellow =
      GameTone(Color(0xFFFFE066), Color(0xFFFFB627), Color(0xFFC27C0E));
  static const blue =
      GameTone(Color(0xFF6CC4FF), Color(0xFF2E8BEA), Color(0xFF1A5BAA));
  static const red =
      GameTone(Color(0xFFFF8A73), Color(0xFFE8473E), Color(0xFFA8241D));
  static const purple =
      GameTone(Color(0xFFD29BFF), Color(0xFFA25AF0), Color(0xFF6A2DB8));
  static const grey =
      GameTone(Color(0xFFD9DEE8), Color(0xFFAEB6C6), Color(0xFF7D869A));

  /// A tone derived from any color (used for track colors).
  factory GameTone.from(Color c) {
    final hsl = HSLColor.fromColor(c);
    return GameTone(
      hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 0.9)).toColor(),
      c,
      hsl.withLightness((hsl.lightness - 0.15).clamp(0.05, 1.0)).toColor(),
    );
  }
}

/// Fonts: a chunky display font for numbers/titles/buttons, a rounded body.
abstract final class GameFonts {
  static TextStyle display({
    double size = 18,
    Color color = Colors.white,
    double? height,
  }) =>
      GoogleFonts.lilitaOne(
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: 0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle body({
    double size = 14,
    Color color = GameColors.ink,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.nunito(fontSize: size, color: color, fontWeight: weight);
}

ThemeData buildGameTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GameColors.bgTop,
      primary: const Color(0xFF2E8BEA),
      surface: GameColors.panel,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: GameColors.ink,
      displayColor: GameColors.ink,
    ),
    scaffoldBackgroundColor: GameColors.bgBottom,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: GameColors.ink.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GameFonts.body(color: Colors.white, size: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GameColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: GameColors.panelBorder, width: 3),
      ),
      titleTextStyle: GameFonts.display(size: 24, color: GameColors.ink),
    ),
  );
}
