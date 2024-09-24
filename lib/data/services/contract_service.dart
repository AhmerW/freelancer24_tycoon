import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/employee_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/data/repositories/location_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/upgrade_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';

class ContractService {
  final SkillRepository skillRepo;
  final UserRepository userRepo;
  final LocationRepository locationRepo;
  final EmployeeRepository employeeRepo;
  final UpgradeRepository upgradeRepo;

  ContractService({
    required this.skillRepo,
    required this.userRepo,
    required this.locationRepo,
    required this.employeeRepo,
    required this.upgradeRepo,
  });

  Contract generateOffer(Location location) {
    List<Skill> unlockedSkills = skillRepo.getSkills();
    List<Skill> lockedSkills =
        skillRepo.getNextNLockedSkills(unlockedSkills, 2);

    double totalUpgradeRate = upgradeRepo.getTotalUpgradeRate();

    // User experience, calculated based on skill level, tier and progress
    int experience = 0;
    for (Skill skill in unlockedSkills) {
      experience += skill.tier * skill.level;
    }
    if (lockedSkills.isNotEmpty) experience += lockedSkills.first.tier * 2;

    /* possible relevant skills for this offer,
      Higher weights (probability) on unlocked skills.
    */
    int relevantSkillCount = lockedSkills.length + unlockedSkills.length;

    // Convert relevant skill to a Probability object
    List<Probability<Skill>> probabilities = (unlockedSkills + lockedSkills)
        .map(
          (s) => Probability<Skill>(
            s,
            // higher probability for unlocked skills
            s.locked
                ? Random().nextDouble() * 50
                : Random().nextDouble() * 100 + Random().nextDouble() * 50,
          ),
        )
        .toList();

    List<Skill> requiredSkills = [];

    // Choose N random skills from the relevant probabilities
    var bag = WeightedRandomBag<Skill>();
    for (var p in probabilities) {
      bag.addEntry(p.element, p.weight);
    }
    for (int i = 0; i < (Random().nextInt((relevantSkillCount))) + 1; i++) {
      var random = bag.getRandom();
      if (random != null && !requiredSkills.contains(random)) {
        requiredSkills.add(random);
      }
    }

    /* Convert the required skills to SkillRequirement objects
      Random level should be in range of unlocked level (no requirement) to +(0-3) of the skill level
    */
    List<SkillRequirement> skillRequirements = requiredSkills
        .map((s) => SkillRequirement(
            skill: s,
            level:
                s.locked ? 1 : Random().nextInt(s.level + Random().nextInt(3))))
        .toList();

    /* Duration of the offer should be based on experience
    */

    int potentialHours = 0;
    int potentialMin = 10; // default to 15 (small experience)
    if (experience >= 40) {
      potentialMin += 20;
    }
    if (experience >= 80) {
      potentialMin += 15;
    }
    if (experience >= 100) {
      potentialMin += 15;
    }
    if (experience >= 120) {
      potentialHours += 1;
    }
    if (experience >= 200) {
      potentialHours += experience ~/ 200;
    }

    Duration completionTime = Duration(
      hours:
          potentialHours == 0 ? 0 : (Random().nextInt(potentialHours)).toInt(),
      minutes: (Random().nextInt(potentialMin) + 1).toInt(),
    );

    /*
    Random based on amount of employees and which location.
    For every employee assigned the pay grade is significantly higher.
    */
    int n = employeeRepo.getHiredEmployees(location.id).length;
    n = n + 1;

    int requiredPeople = n == 1 ? n : randomRange(1, n);

    /* Pay should be a result of duration, experience, required people,  
    and current rate of which money is generated.
    All unlocked skills are also relevant.
    */

    double pay = skillRepo.getTotalSkillsRate() *
        totalUpgradeRate *
        requiredPeople *
        completionTime.inMinutes;

    print("Before: $pay");
    // rate for each skill is relevant
    for (var skill in requiredSkills) {
      pay += skillRepo.getSkillRate(skill);
      // pay for each level above the current level (difference)
      int? unlockedLevel = skillRepo.hasUnlockedSkill(skill);
      if (unlockedLevel != null) {
        if (unlockedLevel > skill.level) {
          pay += (unlockedLevel - skill.level) * 10;
        }
      }
    }
    print("After: $pay");

    String name = location.names[Random().nextInt(location.names.length)];
    String message =
        location.messages[Random().nextInt(location.messages.length)];

    // Occasionally a golden offer will appear, resulting in higher pay. A more "important" client.
    bool goldenOffer = Random().nextDouble() > 0.9;

    final int id = UniqueKey().hashCode;

    int energy = Random().nextInt(20) + 1;

    return Contract(
      id: id,
      name: name,
      pay: pay,
      location: location.id,
      completionTime: completionTime,
      requiredSkills: skillRequirements,
      requiredPeople: requiredPeople,
      message: message,
      golden: goldenOffer,
      accepted: false,
      energy: energy,
    );
  }
}

class WeightedRandomBag<T> {
  final List<Probability<T>> _entries = [];
  double _accumulatedWeight = 0.0;
  final Random _rand = Random();

  void addEntry(T object, double weight) {
    _accumulatedWeight += weight;
    _entries.add(Probability(object, _accumulatedWeight));
  }

  T? getRandom() {
    double r = _rand.nextDouble() * _accumulatedWeight;
    for (var entry in _entries) {
      if (entry.weight >= r) {
        return entry.element;
      }
    }
    return null; // should only happen when there are no entries
  }
}

class Probability<E> {
  E element;
  double weight;
  Probability(this.element, this.weight);
}
