import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freelancer24_tycoon/blocs/users/user_bloc.dart";

import "package:freelancer24_tycoon/data/models/skills/skill.dart";
import "package:freelancer24_tycoon/data/repositories/functions.dart";
import "package:freelancer24_tycoon/data/repositories/skill_repository.dart";
import "package:freelancer24_tycoon/data/repositories/user_repository.dart";

import 'package:collection/collection.dart';
import "package:freelancer24_tycoon/data/services/skill_service.dart";

part "skill_events.dart";
part "skill_state.dart";

class SkillsBloc extends Bloc<SkillEvent, SkillState> {
  final SkillRepository _skillRepository;
  final UserRepository _userRepository;
  late final SkillService _skillService;

  SkillsBloc(this._skillRepository, this._userRepository)
      : super(const SkillsLoaded.empty()) {
    {
      on<LoadSkillsEvent>(_loadSkills);
      on<UnlockNewSkillEvent>(_unlockNewSkill);
      on<UpgradeSkillEvent>(_upgradeSkill);
      on<ResetSkillsEvent>(_resetSkills);
      _skillService = SkillService(_skillRepository);
    }
  }

  Skill? hasUnlockedSkill(Skill skill) {
    if (state is SkillsLoaded) {
      return (state as SkillsLoaded).skills.firstWhereOrNull(
            (s) => s.id == skill.id,
          );
    }
    return null;
  }

  double getUpgradePrice(Skill skill) {
    int tax1 = (skill.level / 10).round();
    int tax2 = (skill.level / 100).round();

    double price = (skill.level * skill.levelPriceRate) + skill.price;

    price = price * (tax1 > 0 ? tax1 : 1);
    price = price * (tax2 > 0 ? tax2 : 1);

    // round
    return roundDouble(price);
  }

  List<Skill> getNextNLockedSkills(List<Skill> unlocked, int n) {
    return _skillService.getNextNLockedSkills(unlocked, n: n);
  }

  Future<void> _loadSkills(
    LoadSkillsEvent event,
    Emitter<SkillState> emit,
  ) async {
    emit(SkillsLoaded(_skillRepository.getSkills()));
  }

  void _unlockNewSkill(
    UnlockNewSkillEvent event,
    Emitter<SkillState> emit,
  ) {
    if (state is SkillsLoaded) {
      if (_userRepository.getBalance() < event.skill.price) {
        return;
      }
      _userRepository.userStreamController
          .add(DecreaseUserBalanceEvent(event.skill.price));

      _skillRepository.unlockSkill(event.skill);

      emit((state as SkillsLoaded).copyWith(
        skills: (state as SkillsLoaded).skills + [event.skill],
      ));
    }
  }

  void _upgradeSkill(UpgradeSkillEvent event, Emitter<SkillState> emit) {
    if (state is SkillsLoaded) {
      if (_userRepository.getBalance() >= getUpgradePrice(event.skill)) {
        double upgradePrice = roundDouble(getUpgradePrice(event.skill));

        _userRepository.userStreamController
            .add(DecreaseUserBalanceEvent(upgradePrice));
        _skillRepository.upgradeSkill(event.skill);

        emit((state as SkillsLoaded)
            .copyWith(skills: (state as SkillsLoaded).skills));
      }
    }
  }

  void _resetSkills(ResetSkillsEvent event, Emitter<SkillState> emit) {
    _skillRepository.resetSkills();
    emit(const SkillsLoaded.empty());
  }
}
