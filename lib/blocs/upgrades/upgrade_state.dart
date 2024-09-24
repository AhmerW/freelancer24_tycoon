part of "upgrade_bloc.dart";

class UpgradeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadedUpgradeState extends UpgradeState {
  final UpgradeCategory coffeeCategory;
  final UpgradeCategory chairCategory;

  LoadedUpgradeState(this.coffeeCategory, this.chairCategory);

  List<UpgradeCategory> get categories => [coffeeCategory, chairCategory];

  LoadedUpgradeState copyWith({
    UpgradeCategory? coffeeCategory,
    UpgradeCategory? chairCategory,
  }) {
    return LoadedUpgradeState(coffeeCategory ?? this.coffeeCategory,
        chairCategory ?? this.chairCategory);
  }

  LoadedUpgradeState copyOnlyWith(UpgradeCategory category) {
    return copyWith(
      coffeeCategory: category.category == UpgradeCategoryType.coffee
          ? category
          : coffeeCategory,
      chairCategory: category.category == UpgradeCategoryType.chair
          ? category
          : chairCategory,
    );
  }

  @override
  List<Object?> get props => [coffeeCategory];
}
