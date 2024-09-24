import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/upgrades/upgrade.dart';

class CurrentUserState {
  final double balance;
  final double rate;
  final int energy;
  final double energyRate;

  CurrentUserState({
    required this.balance,
    required this.rate,
    required this.energy,
    required this.energyRate,
  });
}

class ActiveUserState {
  final CurrentUserState userState;

  final List<Skill> unlockedSkills;
  final List<Skill> nextNSkills;

  final List<Upgrade> unlockedUpgrades;
  final List<Upgrade> nextNUpgrades;

  final List<ActiveLocationState> locations;

  ActiveUserState({
    required this.userState,
    required this.unlockedSkills,
    required this.nextNSkills,
    required this.unlockedUpgrades,
    required this.nextNUpgrades,
    required this.locations,
  });
}
