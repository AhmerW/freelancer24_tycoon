import 'package:freelancer24_tycoon/data/database/json_database.dart';
import 'package:freelancer24_tycoon/data/models/upgrades/upgrade.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

class UpgradeRepository {
  final Map<int, bool> _fetchedUpgrades = {};

  bool _hasFetchedUpgrade(int id) => _fetchedUpgrades[id] ?? false;

  List<UpgradeCategory> getAllUpgradeCategories() {
    return GetIt.I<JsonDatabase>().getAllUpgradeCategories();
  }

  UpgradeCategory? getUpgradeCategoryById(int id) {
    return GetIt.I<JsonDatabase>().getUpgradeCategoryById(id);
  }

  List<Upgrade> getAllUpgradesUpToUnlocked(UpgradeCategory category) {
    List<Upgrade> upgrades = [];
    for (Upgrade u in category.upgrades) {
      if (u.id <= category.currentUpgrade.id) {
        upgrades.add(u);
      }
    }
    return upgrades;
  }

  double getTotalUpgradeRate() {
    double rate = 0;
    List<UpgradeCategory> categories = getAllUpgradeCategories();
    for (UpgradeCategory category in categories) {
      List<Upgrade> upgrades = getAllUpgradesUpToUnlocked(category);
      for (Upgrade u in upgrades) {
        rate += getUpgradeRate(u);
      }
    }
    return rate;
  }

  double getTotalUpgradeExperience() {
    return 0;
  }

  double getUpgradeRate(Upgrade upgrade) {
    return upgrade.price * (upgrade.rate / 100) * (upgrade.level / 10);
  }

  Upgrade? getUpgradeById(int id, int categoryId) {
    UpgradeCategory? upgradeCategory = getUpgradeCategoryById(categoryId);
    if (upgradeCategory == null) return null;
    for (Upgrade u in upgradeCategory.upgrades) {
      if (u.id == id) {
        return u;
      }
    }
    return null;
  }

  Upgrade getCurrentUpgrade(UpgradeCategory category) {
    if (_hasFetchedUpgrade(category.id)) {
      return category.currentUpgrade;
    }
    Box upgradesBox = Hive.box("upgrades");
    // upgrade : level (even tho only one upgrade is relevant, a map is necessary)
    Map<dynamic, dynamic>? upgradeLevelMap = upgradesBox.get(category.id);
    Upgrade upgrade = category.currentUpgrade;
    if (upgradeLevelMap != null && upgradeLevelMap.isNotEmpty) {
      upgrade = getUpgradeById(
            upgradeLevelMap.keys.first,
            category.id,
          ) ??
          upgrade;
      upgrade.level = upgradeLevelMap.values.first;
    }

    category.currentUpgrade = upgrade;
    _fetchedUpgrades[category.id] = true;
    return upgrade;
  }

  void levelUpUpgrade(Upgrade upgrade, UpgradeCategory category) {
    upgrade.level++;
    var box = Hive.box("upgrades");
    box.put(category.id, {upgrade.id: upgrade.level});
  }

  void unlockNextUpgrade(
    UpgradeCategory category,
    Upgrade current,
    Upgrade next,
  ) {
    var box = Hive.box("upgrades");
    box.put(category.id, {next.id: 1});
    category.currentUpgrade = next;
  }

  void resetUpgradeCategory(UpgradeCategory category) {
    var box = Hive.box("upgrades");
    box.put(category.id, {category.upgrades.first.id: 1});
    category.currentUpgrade = category.upgrades.first;
  }
}
