import 'dart:io';
import 'dart:math';

import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';

/// The real game content, read straight from the asset files.
GameContent loadTestContent() => GameContent.fromJsonStrings(
      skillsJson: File('assets/data/skills.json').readAsStringSync(),
      upgradesJson: File('assets/data/upgrades.json').readAsStringSync(),
      locationsJson: File('assets/data/locations.json').readAsStringSync(),
    );

GameEngine testEngine({int seed = 42}) =>
    GameEngine(loadTestContent(), random: Random(seed));

final DateTime t0 = DateTime.utc(2026, 1, 1, 12);
