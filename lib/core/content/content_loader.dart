import 'package:flutter/services.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';

Future<GameContent> loadGameContent([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  return GameContent.fromJsonStrings(
    skillsJson: await b.loadString('assets/data/skills.json'),
    upgradesJson: await b.loadString('assets/data/upgrades.json'),
    locationsJson: await b.loadString('assets/data/locations.json'),
    marketingJson: await b.loadString('assets/data/marketing.json'),
    achievementsJson: await b.loadString('assets/data/achievements.json'),
    chestsJson: await b.loadString('assets/data/chests.json'),
  );
}
