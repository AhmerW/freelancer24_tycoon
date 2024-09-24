import 'dart:async';

import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/user.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';

import 'package:hive/hive.dart';

double defaultBalance = 0.0;
double defaultRate = 1.0;
double defaultEnergyRate = 1.0;
int defaultEnergy = 100;

enum UserProperty { balance, rate, energy, energyRate }

class UserRepository {
  // create stream that skillsRepo can send events to so the UserRepo updates users balance
  final StreamController<UserEvents> userStreamController =
      StreamController<UserEvents>.broadcast();

  Timer? timer;
  double _currentRate = 0;
  double _currentEnergyrate = 0;

  UserRepository();

  double get rate => _currentRate;
  double get energyRate => _currentEnergyrate;

  void setTimer(double rate) {
    // increase balance by this rate
    _currentRate = rate;
    if (timer != null) timer!.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      userStreamController.add(IncreaseUserBalanceEvent(rate));
    });
  }

  CurrentUserState get currentUserState => CurrentUserState(
        balance: getBalance(),
        rate: rate,
        energy: getEnergy(),
        energyRate: energyRate,
      );

  int getEnergy() {
    var nrg =
        (Hive.box("user")).get("energy", defaultValue: defaultEnergy).toInt();
    return nrg;
  }

  double getBalance() {
    return (Hive.box("user")).get("balance", defaultValue: defaultBalance);
  }

  void setBalance(double newBalance) {
    // round to 1 decimal

    Hive.box("user").put("balance", roundDouble(newBalance));
  }

  void setEnergy(double newEnergy) {
    Hive.box("user").put("energy", roundDouble(newEnergy));
  }

  void setRate(double newRate) {
    _currentRate = newRate;
  }

  void setEnergyRate(double newRate) {
    _currentEnergyrate = newRate;
  }

  void increase(double amount, UserProperty property) {
    switch (property) {
      case UserProperty.balance:
        setBalance(getBalance() + amount);
        break;
      case UserProperty.rate:
        setRate(rate + amount);
        break;
      case UserProperty.energy:
        setEnergy(getEnergy() + amount);
        break;
      case UserProperty.energyRate:
        setEnergyRate(energyRate + amount);
        break;
    }
  }

  void decrease(double amount, UserProperty property) {
    switch (property) {
      case UserProperty.balance:
        setBalance(getBalance() - amount);
        break;
      case UserProperty.rate:
        setRate(rate - amount);
        break;
      case UserProperty.energy:
        setEnergy(getEnergy() - amount);
        break;
      case UserProperty.energyRate:
        setEnergyRate(energyRate - amount);
        break;
    }
  }
}
