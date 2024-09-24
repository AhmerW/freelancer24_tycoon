part of "skill_bloc.dart";

class SkillEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSkillsEvent extends SkillEvent {}

class UnlockNewSkillEvent extends SkillEvent {
  final Skill skill;

  UnlockNewSkillEvent(this.skill);

  @override
  List<Object?> get props => [skill];
}

class UpgradeSkillEvent extends SkillEvent {
  final Skill skill;

  UpgradeSkillEvent(this.skill);

  @override
  List<Object?> get props => [skill];
}

class ResetSkillsEvent extends SkillEvent {}
