import 'dart:math';

import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';

class SkillService {
  final SkillRepository _skillRepository;

  SkillService(this._skillRepository);

  List<Skill> getUnlockedSkills() => _skillRepository.getSkills();
  List<Skill> getNextNLockedSkills(List<Skill> skills, {int n = 3}) =>
      _skillRepository.getNextNLockedSkills(skills, 3);

  List<Skill> getNRandomUnlockedSkills() {
    List<Skill> allSkills = _skillRepository.getSkills();
    List<Skill> skills = [];
    for (int i = 0; i < Random().nextInt(allSkills.length); i++) {
      skills.add(allSkills[Random().nextInt(allSkills.length)]);
    }
    return skills;
  }

  List<int> getNRandomUnlockedSkillsIds() =>
      getNRandomUnlockedSkills().map((e) => e.id).toList();
}
