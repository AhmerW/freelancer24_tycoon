part of "skill_bloc.dart";

class SkillState extends Equatable {
  const SkillState();

  @override
  List<Object?> get props => [];
}

class SkillsLoading extends SkillState {}

class SkillsError extends SkillState {
  final String message;

  const SkillsError({
    required this.message,
  });
}

class SkillsLoaded extends SkillState {
  final List<Skill> skills;

  const SkillsLoaded(this.skills);

  const SkillsLoaded.empty() : skills = const [];

  SkillsLoaded copyWith({
    List<Skill>? skills,
  }) {
    return SkillsLoaded(
      skills ?? this.skills,
    );
  }

  @override
  List<Object?> get props => [skills];
}
