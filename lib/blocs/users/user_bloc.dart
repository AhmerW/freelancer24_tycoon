import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/upgrade_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';

part "user_events.dart";
part "user_state.dart";

class UserBloc extends Bloc<UserEvents, UserState> {
  final UserRepository _userRepository;
  final SkillRepository _skillRepository;
  final UpgradeRepository _upgradeRepository;

  UserBloc(this._userRepository, this._skillRepository, this._upgradeRepository)
      : super(UserState()) {
    _userRepository.userStreamController.stream.listen((event) {
      if (event is IncreaseUserBalanceEvent) {
        add(IncreaseUserBalanceEvent(event.balance));
      } else if (event is DecreaseUserBalanceEvent) {
        add(DecreaseUserBalanceEvent(event.balance));
      } else if (event is DecreaseUserEnergyEvent) {
        add(DecreaseUserEnergyEvent(event.energy));
      } else if (event is IncreaseUserEnergyEvent) {
        add(IncreaseUserEnergyEvent(event.energy));
      }
    });
    on<LoadUserEvent>(_loadUser);
    on<IncreaseUserBalanceEvent>(_increaseUserBalanceEvent);
    on<DecreaseUserBalanceEvent>(_decreaseUserBalanceEvent);
    on<SetUserBalaceEvent>(_setUserBalance);
    on<DecreaseUserEnergyEvent>(_decreaseUserEnergyEvent);
    on<SetUserEnergyEvent>(_setUserEnergy);
  }
  bool hasFullenergy() {
    if (state is LoadedUserState) {
      return (state as LoadedUserState).energy == defaultEnergy;
    }
    return false;
  }

  void _loadUser(LoadUserEvent event, Emitter<UserState> emit) {
    // timer is set to 2x the rate of the skill (2 seconds)
    _userRepository.setTimer((_skillRepository.getTotalSkillsRate() +
            _upgradeRepository.getTotalUpgradeRate()) *
        2);

    emit(
      LoadedUserState(
        _userRepository.getBalance(),
        _userRepository.rate,
        _userRepository.getEnergy(),
        _userRepository.energyRate,
      ),
    );
  }

  void _increaseUserBalanceEvent(
    IncreaseUserBalanceEvent event,
    Emitter<UserState> emit,
  ) {
    if (state is LoadedUserState) {
      // round newBalance
      double newBalance = roundDouble(
        ((state as LoadedUserState).balance + event.balance),
      );

      _userRepository.increase(
        roundDouble(event.balance.toDouble()),
        UserProperty.balance,
      );
      emit(LoadedUserState.fromLoadedUserState(
        state as LoadedUserState,
        balance: newBalance,
      ));
    }
  }

  void _decreaseUserBalanceEvent(
      DecreaseUserBalanceEvent event, Emitter<UserState> emit) {
    if (state is LoadedUserState) {
      _userRepository.decrease(
        event.balance.toDouble(),
        UserProperty.balance,
      );
      emit(LoadedUserState.fromLoadedUserState(
        state as LoadedUserState,
        balance: (state as LoadedUserState).balance - event.balance,
      ));
    }
  }

  void _setUserBalance(SetUserBalaceEvent event, Emitter<UserState> emit) {
    if (state is LoadedUserState) {
      _userRepository.setBalance(event.balance);
      emit(LoadedUserState.fromLoadedUserState(
        state as LoadedUserState,
        balance: event.balance,
      ));
    }
  }

  void _setUserEnergy(SetUserEnergyEvent event, Emitter<UserState> emit) {
    if (state is LoadedUserState) {
      _userRepository.setEnergy(event.energy.toDouble());
      emit(LoadedUserState.fromLoadedUserState(
        state as LoadedUserState,
        energy: event.energy,
      ));
    }
  }

  void _decreaseUserEnergyEvent(
    DecreaseUserEnergyEvent event,
    Emitter<UserState> emit,
  ) {
    if (state is LoadedUserState) {
      _userRepository.decrease(
        event.energy.toDouble(),
        UserProperty.energy,
      );
      emit(LoadedUserState.fromLoadedUserState(
        state as LoadedUserState,
        energy: (state as LoadedUserState).energy - event.energy,
      ));
    }
  }
}
