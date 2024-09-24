enum UpgradeCategoryType { laptop, chair, coffee }

class UpgradeCategory {
  final UpgradeCategoryType category;

  Upgrade currentUpgrade;
  final int id;

  final List<Upgrade> upgrades;

  UpgradeCategory({
    required this.id,
    required this.category,
    required this.upgrades,
    required this.currentUpgrade,
  });

  factory UpgradeCategory.fromJson(Map<String, dynamic> json) {
    var upgrades =
        (json['upgrades'] as List).map((e) => Upgrade.fromJson(e)).toList();
    return UpgradeCategory(
      id: json['id'],
      category: json["category"] == "laptop"
          ? UpgradeCategoryType.laptop
          : json["category"] == "coffee"
              ? UpgradeCategoryType.coffee
              : UpgradeCategoryType.chair,
      upgrades: upgrades,
      currentUpgrade: upgrades.first,
    );
  }
}

class CurrentUpgradeCategoryState {
  final UpgradeCategory category;
  final Upgrade currentUpgrade;

  CurrentUpgradeCategoryState({
    required this.category,
    required this.currentUpgrade,
  });
}

/*
A single upgrade, such as a "PC rtx 4080" or the "Gaming chair 3000".
*/
class Upgrade {
  final int id;

  final String name;
  final String description;
  final int price;
  final int rate;
  final int unlockOnPreviousLevel;
  final String icon;
  final int tier;
  final double levelPriceRate;
  int level;

  Upgrade({
    required this.id,
    required this.name,
    required this.price,
    required this.rate,
    required this.description,
    required this.unlockOnPreviousLevel,
    required this.icon,
    required this.tier,
    required this.levelPriceRate,
    this.level = 1,
  });

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    return Upgrade(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      rate: json['rate'],
      unlockOnPreviousLevel: json['unlockOnPreviousLevel'],
      icon: json['icon'],
      tier: json['tier'],
      levelPriceRate: json['levelPriceRate'],
    );
  }
}
