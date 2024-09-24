class Skill {
  final int id;
  final int tier;
  int level;
  final String name;
  final String description;
  final double price;
  final double levelPriceRate;
  final double rate; // rate schange (usually increase) in percentage
  bool locked;
  final String icon;
  final int unlockOnPreviousLevel;

  Skill({
    required this.id,
    required this.tier,
    this.level = 1, // default level
    required this.name,
    required this.price,
    required this.rate,
    required this.description,
    required this.levelPriceRate,
    this.locked = false,
    required this.icon,
    required this.unlockOnPreviousLevel,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
        id: json['id'],
        tier: json['tier'],
        level: json['level'] ?? 1,
        name: json['name'],
        price:
            (json['price'] is int) ? json['price'].toDouble() : json['price'],
        rate: json['rate'],
        description: json['description'],
        levelPriceRate: json['levelPriceRate'],
        icon: json["icon"],
        unlockOnPreviousLevel: json['unlockOnPreviousLevel'] ?? 0);
  }
  //copyWith
  Skill copyWith({
    int? id,
    int? tier,
    int? level,
    String? name,
    String? description,
    double? price,
    double? levelPriceRate,
    double? rate,
    String? icon,
    int? unlockOnPreviousLevel,
  }) {
    return Skill(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      level: level ?? this.level,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      levelPriceRate: levelPriceRate ?? this.levelPriceRate,
      rate: rate ?? this.rate,
      icon: icon ?? this.icon,
      unlockOnPreviousLevel:
          unlockOnPreviousLevel ?? this.unlockOnPreviousLevel,
    );
  }

  // overide equal
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Skill && other.id == id;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier,
      'level': level,
      'name': name,
      'price': price,
      'rate': rate,
      'description': description,
      'levelPriceRate': levelPriceRate,
      'icon': icon,
      'unlockOnPreviousLevel': unlockOnPreviousLevel,
    };
  }
}

class CurrentSkillState {
  final List<Skill> skills;

  CurrentSkillState({
    required this.skills,
  });
}

class SkillRequirementId {
  final int skillId;
  final int level;

  bool matchesSkill(int id, int lvl) => skillId == id && lvl >= level;

  SkillRequirementId({
    required this.skillId,
    required this.level,
  });

  factory SkillRequirementId.fromJson(Map<String, dynamic> json) {
    return SkillRequirementId(
      skillId: json['skillId'],
      level: json['level'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'level': level,
    };
  }
}

class SkillRequirement {
  final Skill skill;
  final int level;

  SkillRequirement({
    required this.skill,
    required this.level,
  });

  factory SkillRequirement.fromJson(Map<String, dynamic> json) {
    return SkillRequirement(
      skill: Skill.fromJson(json['skill']),
      level: json['level'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'skill': skill.toJson(),
      'level': level,
    };
  }
}
