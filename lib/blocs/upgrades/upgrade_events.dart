part of "upgrade_bloc.dart";

class UpgradeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUpgradesEvent extends UpgradeEvent {}

class LevelUpUpgradeEvent extends UpgradeEvent {
  final UpgradeCategory category;
  final Upgrade upgrade;

  LevelUpUpgradeEvent(this.category, this.upgrade);

  @override
  List<Object?> get props => [category, upgrade];
}

class ResetUpgradesEvent extends UpgradeEvent {
  final UpgradeCategory category;

  ResetUpgradesEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class ResetAllUpgradesEvent extends UpgradeEvent {}
