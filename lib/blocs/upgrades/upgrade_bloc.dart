import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/upgrades/upgrade.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/data/repositories/upgrade_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';

part "upgrade_events.dart";
part "upgrade_state.dart";

class UpgradeBloc extends Bloc<UpgradeEvent, UpgradeState> {
  final UpgradeRepository _upgradeRepository;
  final UserRepository _userRepository;
  UpgradeBloc(
    this._upgradeRepository,
    this._userRepository,
  ) : super(UpgradeState()) {
    on<LevelUpUpgradeEvent>(_onLevelUpUpgrade);
    on<LoadUpgradesEvent>(_onLoadUpgrade);
    on<ResetUpgradesEvent>(_onResetUpgrade);
    on<ResetAllUpgradesEvent>(_onResetAllUpgrades);
  }

  Upgrade? getNextUpgrade(UpgradeCategory category) {
    if (state is LoadedUpgradeState) {
      for (int i = 0; i < category.upgrades.length; i++) {
        if (category.upgrades[i].id == category.currentUpgrade.id) {
          if (i + 1 < category.upgrades.length) {
            return category.upgrades[i + 1];
          } else {
            return null;
          }
        }
      }
    }
    return null;
  }

  double getUpgradePrice(Upgrade upgrade) {
    double price = (upgrade.level * upgrade.levelPriceRate) + upgrade.price;

    price = price * upgrade.tier * 10;

    // round
    return roundDouble(price);
  }

  void _onLoadUpgrade(LoadUpgradesEvent event, Emitter<UpgradeState> emit) {
    List<UpgradeCategory> categories =
        _upgradeRepository.getAllUpgradeCategories();
    var s = LoadedUpgradeState(
      categories[0],
      categories[1],
    );
    for (var cat in categories) {
      cat.currentUpgrade = _upgradeRepository.getCurrentUpgrade(cat);
    }

    emit(s);
  }

  void _unlockNextLevel(
    UpgradeCategory category,
    Upgrade current,
    Upgrade next,
    Emitter<UpgradeState> emit,
  ) {
    if (state is LoadedUpgradeState) {
      _upgradeRepository.unlockNextUpgrade(category, current, next);
      category.currentUpgrade = next;
      emit((state as LoadedUpgradeState).copyOnlyWith(category));
    }
  }

  void _onLevelUpUpgrade(
    LevelUpUpgradeEvent event,
    Emitter<UpgradeState> emit,
  ) {
    if (state is LoadedUpgradeState) {
      double price = getUpgradePrice(event.upgrade);
      Upgrade? nextUpgrade = getNextUpgrade(event.category);

      if (nextUpgrade != null &&
          event.upgrade.level + 1 >= nextUpgrade.unlockOnPreviousLevel) {
        return _unlockNextLevel(
          event.category,
          event.upgrade,
          nextUpgrade,
          emit,
        );
      }
      if (_userRepository.getBalance() < price) {
        return;
      }
      _upgradeRepository.levelUpUpgrade(event.upgrade, event.category);
      _userRepository.userStreamController.add(
        DecreaseUserBalanceEvent(price),
      );
      emit((state as LoadedUpgradeState).copyOnlyWith(event.category));
    }
  }

  void _onResetUpgrade(
    ResetUpgradesEvent event,
    Emitter<UpgradeState> emit,
  ) {
    if (state is LoadedUpgradeState) {
      _upgradeRepository.resetUpgradeCategory(event.category);
      event.category.currentUpgrade = event.category.upgrades.first;
      for (var u in event.category.upgrades) {
        u.level = 0;
      }
      emit((state as LoadedUpgradeState).copyOnlyWith(event.category));
    }
  }

  void _onResetAllUpgrades(
    ResetAllUpgradesEvent event,
    Emitter<UpgradeState> emit,
  ) {
    if (state is LoadedUpgradeState) {
      for (var cat in (state as LoadedUpgradeState).categories) {
        _onResetUpgrade(ResetUpgradesEvent(cat), emit);
      }
    }
  }
}
