import 'dart:math';

import 'package:freelancer24_tycoon/data/database/json_database.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

List<int> defaultSkills = [0, 1, 2];

class SkillRepository {
  Map<int, int> mappedSkills = {};

  CurrentSkillState get currentSkillState => CurrentSkillState(
        skills: getSkills(),
      );

  double getTotalSkillsRate() {
    double rate = 0;
    List<Skill> skills = getSkills();
    for (Skill skill in skills) {
      rate += getSkillRate(skill);
    }
    return rate;
  }

  List<Skill> getAllSkills() {
    return GetIt.I<JsonDatabase>().getAllSkills();
  }

  List<Skill> generateNRandomUnlockedSkills(int n) {
    List<Skill> gen(List<Skill> s) {
      List<Skill> l = [];
      for (int i = 0; i < s.length; i++) {
        var r = s[Random().nextInt(s.length)];
        if (!l.contains(r)) {
          l.add(r);
        }
      }
      return l;
    }

    List<Skill> all = getSkills();
    List<Skill> skills = [];
    while (true) {
      if (skills.length >= n) {
        break;
      }
      skills.addAll(gen(all));
    }
    return skills;
  }

  List<Skill> getSkills() {
    List<Skill> skills = [];
    var skillLevelMap = getSkillLevelMap();
    var allSkills = getAllSkills();
    for (var skill in allSkills) {
      if (skillLevelMap.containsKey(skill.id)) {
        skills.add(skill.copyWith(level: skillLevelMap[skill.id]));
        skill.locked = false;
      } else {
        skill.locked = true;
      }
    }
    return skills;
  }

  Map<int, int> getSkillLevelMap() {
    // All unlocked skills mapped to their level
    if (mappedSkills.isNotEmpty) {
      return mappedSkills;
    }
    var skillsBox = Hive.box("skills");

    var boxes = skillsBox.toMap();
    if (boxes.isEmpty) {
      for (int skill in defaultSkills) {
        skillsBox.put(skill, 1); // skill : level
      }
      mappedSkills = {for (var e in defaultSkills) e: 1};
      return mappedSkills;
    }

    for (var key in boxes.keys) {
      mappedSkills[key] = boxes[key];
    }

    return mappedSkills;
  }

  List<Skill> getNextNLockedSkills(
    List<Skill> unlocked,
    int n,
  ) {
    if (unlocked.isEmpty) {
      return [];
    }

    Skill max = unlocked.reduce(
      (value, element) => value.id > element.id ? value : element,
    );
    List<Skill> locked = [];
    for (int i = 0; i < n; i++) {
      Skill? skill = getSkill(max.id + i + 1);

      if (skill == null) {
        continue;
      }
      skill.locked = true;
      locked.add(skill);
    }

    return locked;
  }

  void resetSkills() {
    var skillsBox = Hive.box("skills");
    skillsBox.clear();
    mappedSkills = {};
  }

  Skill? getSkill(int n) {
    return GetIt.I<JsonDatabase>().getSkill(n);
  }

  void setSkillLevel(int skillId, int level) async {
    var skillsBox = Hive.box("skills");
    skillsBox.put(skillId, level);
  }

  int? hasUnlockedSkill(Skill skill) {
    return mappedSkills.containsKey(skill.id) ? mappedSkills[skill.id] : null;
  }

  void upgradeSkill(Skill skill) {
    var skillsBox = Hive.box("skills");
    skill.level++;
    mappedSkills[skill.id] = skill.level;
    skillsBox.put(skill.id, skill.level);
  }

  void unlockSkill(Skill skill) {
    var skillsBox = Hive.box("skills");
    skill.locked = false;
    skillsBox.put(skill.id, 1);
    mappedSkills[skill.id] = 1;
  }

  double getSkillRate(Skill skill) {
    return skill.price * (skill.rate / 100) * (skill.level / 10);
  }
}
