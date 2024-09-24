part of "user_bloc.dart";

class UserEvents extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserEvent extends UserEvents {}

class IncreaseUserBalanceEvent extends UserEvents {
  final double balance;
  IncreaseUserBalanceEvent(this.balance);
}

class DecreaseUserBalanceEvent extends UserEvents {
  final double balance;
  DecreaseUserBalanceEvent(this.balance);
}

class DecreaseUserEnergyEvent extends UserEvents {
  final int energy;
  DecreaseUserEnergyEvent(this.energy);
}

class IncreaseUserEnergyEvent extends UserEvents {
  final int energy;
  IncreaseUserEnergyEvent(this.energy);
}

class SetUserRateEvent extends UserEvents {
  final int rate;
  SetUserRateEvent(this.rate);
}

class SetUserBalaceEvent extends UserEvents {
  final double balance;
  SetUserBalaceEvent(this.balance);
}

class SetUserEnergyEvent extends UserEvents {
  final int energy;
  SetUserEnergyEvent(this.energy);
}
