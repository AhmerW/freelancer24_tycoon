import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/repositories/contract_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/employee_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/location_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/upgrade_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';
import 'package:freelancer24_tycoon/data/services/contract_service.dart';

part "contract_events.dart";
part "contract_state.dart";

class ContractBloc extends Bloc<ContractEvent, ContractState> {
  final ContractRepository _contractRepository;
  final UserRepository _userRepository;
  final LocationRepository _locationRepository;
  final SkillRepository _skillRepository;
  final EmployeeRepository _employeeRepository;
  final UpgradeRepository _upgradeRepository;

  late final ContractService _contractService;

  ContractBloc(
      this._contractRepository,
      this._userRepository,
      this._locationRepository,
      this._skillRepository,
      this._employeeRepository,
      this._upgradeRepository)
      : super(const LoadedContractState.empty()) {
    on<AcceptContractEvent>(_acceptContract);
    on<RejectContractEvent>(_rejectContract);
    on<CancelContractEvent>(_cancelContract);
    on<LoadContracsEvent>(_loadContracts);

    _contractService = ContractService(
      skillRepo: _skillRepository,
      locationRepo: _locationRepository,
      employeeRepo: _employeeRepository,
      userRepo: _userRepository,
      upgradeRepo: _upgradeRepository,
    );
  }

  Contract generateOffer(Location location) {
    return _contractService.generateOffer(location);
  }

  List<Contract> getContractsGenIfEmpty(Location location) {
    List<Contract> contracts = _contractRepository.getContracts(location);
    int unassigned = _employeeRepository
        .getEmployees(location.id)
        .map((element) => element.assignedTo == null)
        .length;

    if (contracts.length < location.maxEmployees) {
      for (int i = 0; i < location.maxEmployees - contracts.length; i++) {
        var offer = generateOffer(
          location,
        );
        _contractRepository.addContract(offer, location);
      }

      return _contractRepository.getContracts(location);
    }
    // remove dupe of objects

    return contracts;
  }

  void _acceptContract(
    AcceptContractEvent event,
    Emitter<ContractState> emit,
  ) {
    if (state is LoadedContractState) {
      if (_userRepository.getEnergy() < event.offer.energy) {
        return;
      }
      if (event.assignedTo.length > event.offer.requiredPeople) {
        return;
      }
      event.offer.assignedTo = event.assignedTo.map((e) => e.id).toList();
      _userRepository.userStreamController
          .add(DecreaseUserEnergyEvent(event.offer.energy));
      _contractRepository.acceptContract(event.offer, event.location);
      emit(LoadedContractState(_contractRepository.getAllContracts()));
    }
  }

  void _rejectContract(
    RejectContractEvent event,
    Emitter<ContractState> emit,
  ) {
    if (state is LoadedContractState) {
      _contractRepository.removeContract(event.offer);
      emit(LoadedContractState(_contractRepository.getAllContracts()));
    }
  }

  void _cancelContract(
    CancelContractEvent event,
    Emitter<ContractState> emit,
  ) {
    if (state is LoadedContractState) {
      if (event.contract.accepted && event.contract.isFinished) {
        // finished
        _userRepository.userStreamController.add(
          IncreaseUserBalanceEvent(event.contract.pay),
        );
      }
      _contractRepository.cancelContract(event.contract);
      emit(LoadedContractState(_contractRepository.getAllContracts()));
    }
  }

  void _loadContracts(
    LoadContracsEvent event,
    Emitter<ContractState> emit,
  ) {
    emit(LoadedContractState(_contractRepository.getAllContracts()));
  }
}
