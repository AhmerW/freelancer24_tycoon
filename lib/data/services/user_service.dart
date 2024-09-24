import 'dart:async';

import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/user.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';
import 'package:freelancer24_tycoon/data/services/contract_service.dart';
import 'package:freelancer24_tycoon/data/services/employee_service.dart';
import 'package:freelancer24_tycoon/data/services/skill_service.dart';

class UserService {
  final UserRepository _userRepository;

  final EmployeeService employeeService;
  final ContractService contractService;
  final SkillService skillService;

  StreamController<UserEvents> get stream =>
      _userRepository.userStreamController;

  UserService(
    this._userRepository, {
    required this.employeeService,
    required this.contractService,
    required this.skillService,
  });

  ActiveUserState getCurrentUserState() {
    return ActiveUserState(
      userState: CurrentUserState(
        balance: 0,
        energy: 0,
        energyRate: 0,
        rate: 0,
      ),
      unlockedSkills: [],
      nextNSkills: [],
      unlockedUpgrades: [],
      nextNUpgrades: [],
      locations: [],
    );
  }
}
