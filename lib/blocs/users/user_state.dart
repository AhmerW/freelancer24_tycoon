part of "user_bloc.dart";

class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadedUserState extends UserState {
  final double balance;
  final double rate;
  final int energy;
  final double energyRate;
  LoadedUserState(
    this.balance,
    this.rate,
    this.energy,
    this.energyRate,
  );

  bool get hasFullenergy => energy == defaultEnergy;

  LoadedUserState copyWith(
      {double? balance, double? rate, int? energy, double? energyRate}) {
    return LoadedUserState(
      balance ?? this.balance,
      rate ?? this.rate,
      energy ?? this.energy,
      energyRate ?? this.energyRate,
    );
  }

  factory LoadedUserState.fromLoadedUserState(LoadedUserState state,
      {double? balance, double? rate, int? energy, double? energyRate}) {
    return LoadedUserState(
      balance ?? state.balance,
      rate ?? state.rate,
      energy ?? state.energy,
      energyRate ?? state.energyRate,
    );
  }

  @override
  List<Object?> get props => [balance, rate, energy, energyRate];
}
