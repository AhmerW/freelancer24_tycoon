import 'dart:convert';

/// Static, read-only game content loaded from `assets/data/*.json`.
///
/// Nothing in here changes while the game runs. Player progress lives in
/// `GameState`; these classes only describe what exists in the game.

class SkillDef {
  final int id;

  /// Stable text id, e.g. "html".
  final String key;

  /// Id of the [TrackDef] this skill belongs to.
  final String track;

  /// Position inside its track, starting at 1.
  final int step;

  /// Position on the global economy curve. Later = pricier, and less income
  /// per dollar spent (see `Balance.skillIncomeDecay`).
  final double rank;
  final int tier;
  final String name;
  final String description;

  /// Price to unlock the skill. Also the base for its income and level costs.
  final double price;

  /// Income strength of the skill (percent of [price] per second per level,
  /// before the per-tier decay in `Balance`).
  final double rate;

  /// Steepness of the level-up cost curve.
  final double levelPriceRate;
  final String icon;

  /// Level the previous skill must reach before this one can be unlocked.
  final int unlockOnPreviousLevel;

  const SkillDef({
    required this.id,
    required this.key,
    required this.track,
    required this.step,
    required this.rank,
    required this.tier,
    required this.name,
    required this.description,
    required this.price,
    required this.rate,
    required this.levelPriceRate,
    required this.icon,
    required this.unlockOnPreviousLevel,
  });

  factory SkillDef.fromJson(Map<String, dynamic> json) => SkillDef(
        id: json['id'] as int,
        key: json['key'] as String,
        track: json['track'] as String,
        step: json['step'] as int,
        rank: (json['rank'] as num).toDouble(),
        tier: json['tier'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        rate: (json['rate'] as num).toDouble(),
        levelPriceRate: (json['levelPriceRate'] as num).toDouble(),
        icon: json['icon'] as String,
        unlockOnPreviousLevel: (json['unlockOnPreviousLevel'] as int?) ?? 0,
      );
}

/// A career track: a ladder of related skills (e.g. Web Development).
class TrackDef {
  final String id;
  final String name;
  final String description;

  /// Material icon name (see `skillMaterialIcons` in the UI).
  final String icon;

  /// ARGB color.
  final int color;

  /// The track opens once the player has learned this many skills in total.
  final int unlockAtSkills;

  const TrackDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlockAtSkills,
  });

  factory TrackDef.fromJson(Map<String, dynamic> json) => TrackDef(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        color: 0xFF000000 |
            int.parse((json['color'] as String).replaceFirst('#', ''),
                radix: 16),
        unlockAtSkills: json['unlockAtSkills'] as int,
      );
}

/// What an upgrade line improves.
enum UpgradeEffect { income, energyRegen }

class UpgradeItemDef {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int tier;

  /// Price to buy this item (moving the line to it).
  final double price;

  /// Bonus in percent per level of this item.
  final double rate;
  final double levelPriceRate;

  /// Level the previous item must reach before this item can be bought.
  final int unlockOnPreviousLevel;

  const UpgradeItemDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.price,
    required this.rate,
    required this.levelPriceRate,
    required this.unlockOnPreviousLevel,
  });

  factory UpgradeItemDef.fromJson(Map<String, dynamic> json) => UpgradeItemDef(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        tier: json['tier'] as int,
        price: (json['price'] as num).toDouble(),
        rate: (json['rate'] as num).toDouble(),
        levelPriceRate: (json['levelPriceRate'] as num).toDouble(),
        unlockOnPreviousLevel: (json['unlockOnPreviousLevel'] as int?) ?? 0,
      );
}

/// A line of upgrades such as "coffee" or "chair". The player owns one item of
/// each line at a time and levels it up before buying the next item.
class UpgradeLineDef {
  final int id;

  /// Category name; also the folder under `assets/icons/upgrades/`.
  final String category;
  final UpgradeEffect effect;
  final List<UpgradeItemDef> items;

  const UpgradeLineDef({
    required this.id,
    required this.category,
    required this.effect,
    required this.items,
  });

  factory UpgradeLineDef.fromJson(Map<String, dynamic> json) => UpgradeLineDef(
        id: json['id'] as int,
        category: json['category'] as String,
        effect: json['effect'] == 'energyRegen'
            ? UpgradeEffect.energyRegen
            : UpgradeEffect.income,
        items: (json['upgrades'] as List)
            .map((e) => UpgradeItemDef.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class LocationDef {
  final int id;
  final String city;
  final String country;
  final String abbreviation;
  final int tier;
  final double price;

  /// Pay multiplier for contracts in this location.
  final double rate;

  /// Position on the world map as a fraction of the map size.
  final double widthMultiplier;
  final double heightMultiplier;
  final List<String> names;
  final List<String> messages;
  final String message;
  final String icon;
  final int maxOffers;
  final int maxEmployees;
  final double employeeSlotPrice;
  final int maxEmployeeOffers;
  final double employeeSlotPriceRate;

  const LocationDef({
    required this.id,
    required this.city,
    required this.country,
    required this.abbreviation,
    required this.tier,
    required this.price,
    required this.rate,
    required this.widthMultiplier,
    required this.heightMultiplier,
    required this.names,
    required this.messages,
    required this.message,
    required this.icon,
    required this.maxOffers,
    required this.maxEmployees,
    required this.employeeSlotPrice,
    required this.maxEmployeeOffers,
    required this.employeeSlotPriceRate,
  });

  factory LocationDef.fromJson(Map<String, dynamic> json) => LocationDef(
        id: json['id'] as int,
        city: json['city'] as String,
        country: json['country'] as String,
        abbreviation: json['abbreviation'] as String,
        tier: json['tier'] as int,
        price: (json['price'] as num).toDouble(),
        rate: (json['rate'] as num).toDouble(),
        widthMultiplier: (json['widthMultiplier'] as num).toDouble(),
        heightMultiplier: (json['heightMultiplier'] as num).toDouble(),
        names: List<String>.unmodifiable(json['names'] as List),
        messages: List<String>.unmodifiable(json['messages'] as List),
        message: json['message'] as String,
        icon: json['icon'] as String,
        maxOffers: json['maxOffers'] as int,
        maxEmployees: json['maxEmployees'] as int,
        employeeSlotPrice: (json['employeeSlotPrice'] as num).toDouble(),
        maxEmployeeOffers: json['maxEmployeeOffers'] as int,
        employeeSlotPriceRate:
            (json['employeeSlotPriceRate'] as num).toDouble(),
      );
}

class GameContent {
  /// In the order they open.
  final List<TrackDef> tracks;

  /// Ordered by id.
  final List<SkillDef> skills;
  final List<UpgradeLineDef> upgradeLines;

  /// Ordered by price, so the starting (free) location comes first.
  final List<LocationDef> locations;

  final Map<int, SkillDef> _skillsById;
  final Map<String, TrackDef> _tracksById;
  final Map<String, List<SkillDef>> _skillsByTrack;
  final Map<int, UpgradeLineDef> _linesById;
  final Map<int, LocationDef> _locationsById;

  GameContent({
    required List<TrackDef> tracks,
    required List<SkillDef> skills,
    required List<UpgradeLineDef> upgradeLines,
    required List<LocationDef> locations,
  })  : tracks = List.unmodifiable(
            [...tracks]..sort((a, b) => a.unlockAtSkills - b.unlockAtSkills)),
        skills = List.unmodifiable([...skills]..sort((a, b) => a.id - b.id)),
        upgradeLines = List.unmodifiable(upgradeLines),
        locations = List.unmodifiable(
            [...locations]..sort((a, b) => a.price.compareTo(b.price))),
        _skillsById = {for (final s in skills) s.id: s},
        _tracksById = {for (final t in tracks) t.id: t},
        _skillsByTrack = {
          for (final t in tracks)
            t.id: List.unmodifiable(
                skills.where((s) => s.track == t.id).toList()
                  ..sort((a, b) => a.step - b.step)),
        },
        _linesById = {for (final l in upgradeLines) l.id: l},
        _locationsById = {for (final l in locations) l.id: l} {
    if (this.tracks.isEmpty || this.skills.isEmpty || this.locations.isEmpty) {
      throw const FormatException(
          'Game content needs tracks, skills and locations');
    }
    for (final skill in this.skills) {
      if (!_tracksById.containsKey(skill.track)) {
        throw FormatException(
            'Skill ${skill.key} has unknown track ${skill.track}');
      }
    }
  }

  factory GameContent.fromJsonStrings({
    required String skillsJson,
    required String upgradesJson,
    required String locationsJson,
  }) {
    final skillsData = jsonDecode(skillsJson) as Map<String, dynamic>;
    final tracks = (skillsData['tracks'] as List)
        .map((e) => TrackDef.fromJson(e as Map<String, dynamic>))
        .toList();
    final skills = (skillsData['skills'] as List)
        .map((e) => SkillDef.fromJson(e as Map<String, dynamic>))
        .toList();
    final lines = (jsonDecode(upgradesJson)['upgrades'] as List)
        .map((e) => UpgradeLineDef.fromJson(e as Map<String, dynamic>))
        .toList();
    final locations = (jsonDecode(locationsJson)['locations'] as List)
        .map((e) => LocationDef.fromJson(e as Map<String, dynamic>))
        .toList();
    return GameContent(
      tracks: tracks,
      skills: skills,
      upgradeLines: lines,
      locations: locations,
    );
  }

  SkillDef skill(int id) => _skillsById[id]!;
  SkillDef? skillOrNull(int id) => _skillsById[id];

  TrackDef track(String id) => _tracksById[id]!;

  /// Skills of a track, ordered by step.
  List<SkillDef> skillsInTrack(String trackId) => _skillsByTrack[trackId]!;

  /// The skill before this one in its track, or null for a first step.
  SkillDef? previousSkill(int id) {
    final skill = this.skill(id);
    final inTrack = skillsInTrack(skill.track);
    final i = inTrack.indexOf(skill);
    return i <= 0 ? null : inTrack[i - 1];
  }

  UpgradeLineDef upgradeLine(int id) => _linesById[id]!;
  LocationDef location(int id) => _locationsById[id]!;
  LocationDef? locationOrNull(int id) => _locationsById[id];

  SkillDef get startingSkill => skillsInTrack(tracks.first.id).first;
  LocationDef get startingLocation => locations.first;
}
