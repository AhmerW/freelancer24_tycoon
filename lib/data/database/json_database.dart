// Hardcoded data

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/models/upgrades/upgrade.dart';

class JsonDatabase {
  Map<int, Skill> skills = {};
  Map<int, UpgradeCategory> upgrades = {};
  Map<int, int> certificates = {};
  Map<int, Location> locations = {};

  static Future<JsonDatabase> create() async {
    var db = JsonDatabase();
    await db.loadSkills();
    await db.loadUpgrades();
    await db.loadLocations();
    return db;
  }

  Future<void> loadSkills() async {
    String value = await rootBundle.loadString('assets/data/skills.json');

    Map<String, dynamic> data = jsonDecode(value);
    List<Skill> skillslist = (data["skills"] as List<dynamic>)
        .map((e) => Skill.fromJson(e))
        .toList();
    for (var skill in skillslist) {
      skills[skill.id] = skill;
    }
  }

  Future<void> loadUpgrades() async {
    String value = await rootBundle.loadString('assets/data/upgrades.json');
    Map<String, dynamic> data = jsonDecode(value);
    List<UpgradeCategory> upgradeslist = (data["upgrades"] as List<dynamic>)
        .map((e) => UpgradeCategory.fromJson(e))
        .toList();
    for (var upgrade in upgradeslist) {
      upgrades[upgrade.id] = upgrade;
    }
  }

  Future<void> loadLocations() async {
    String value = await rootBundle.loadString('assets/data/locations.json');
    Map<String, dynamic> data = jsonDecode(value);
    List<Location> locationslist = (data["locations"] as List<dynamic>)
        .map((e) => Location.fromJson(e))
        .toList();
    for (var location in locationslist) {
      locations[location.id] = location;
    }
  }

  List<Skill> getAllSkills() {
    return skills.values.toList();
  }

  Skill? getSkill(int id) {
    return skills[id];
  }

  List<Location> getAllLocations() {
    return locations.values.toList();
  }

  List<UpgradeCategory> getAllUpgradeCategories() {
    return upgrades.values.toList();
  }

  UpgradeCategory? getUpgradeCategoryById(int id) {
    return upgrades[id];
  }
}
