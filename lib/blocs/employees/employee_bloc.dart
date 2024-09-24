import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert_widgets.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/alert_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/employee_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';
import 'package:freelancer24_tycoon/data/services/employee_service.dart';

part "employee_events.dart";
part "employee_state.dart";

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final EmployeeRepository _employeeRepository;
  final UserRepository _userRepository;
  final SkillRepository _skillRepository;
  final AlertRepository _alertRepository;

  late final EmployeeService _employeeService;

  EmployeeBloc(
    this._employeeRepository,
    this._alertRepository,
    this._userRepository,
    this._skillRepository,
  ) : super(const LoadedEmployeeState.empty()) {
    on<HireEmployeeEvent>(_hireEmployee);
    on<RejectEmployeeEvent>(_rejectEmployee);
    on<FireEmployeeEvent>(_fireEmployee);
    on<LoadEmployeesEvent>(_loadEmployees);

    _employeeService = EmployeeService(
      _employeeRepository,
      _skillRepository,
    );
  }
  List<Employee> getEmployeeFromIds(Location location, List<int> ids) {
    List<Employee> emps = _employeeRepository.getEmployees(location.id);

    Map<int, Employee> employees = {for (var e in emps) e.id: e};
    employees[0] = Employee.freelancer();
    List<Employee> found = [];
    for (int id in ids) {
      if (employees.containsKey(id)) {
        found.add(employees[id]!);
      }
    }
    return found;
  }

  List<UnhiredEmployee> getUnhiredEmployeesGenIfLess(Location location) {
    return employeeToUnhired(
      _employeeService.getUnhiredEmployeesGenIfLess(location, _skillRepository),
      location,
    );
  }

  List<Employee> getUnassignedEmployees(Location location) {
    return _employeeRepository
        .getHiredEmployees(location.id)
        .where((element) => element.assignedTo == null)
        .toList();
  }

  List<Skill> getEmployeeSkills(Employee employee) {
    List<Skill> skills = [];
    for (SkillRequirementId sk in employee.skills) {
      Skill? s = _skillRepository.getSkill(sk.skillId);
      if (s != null) {
        skills.add(s);
      }
    }
    return skills;
  }

  void _loadEmployees(
    LoadEmployeesEvent event,
    Emitter<EmployeeState> emit,
  ) {
    emit(LoadedEmployeeState(_employeeRepository.getAllEmployees()));
  }

  void _hireEmployee(
    HireEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is LoadedEmployeeState) {
      if (_userRepository.getBalance() < event.employee.hireCost) {
        return;
      }

      _userRepository.userStreamController
          .add(DecreaseUserBalanceEvent(event.employee.hireCost.toDouble()));
      _alertRepository.alertStreamController.add(
          PushAlertEvent(employeeHiredAlert(event.employee, event.location)));
      _employeeRepository.hireEmployee(event.employee);

      emit(LoadedEmployeeState(_employeeRepository.getAllEmployees()));
    }
  }

  void _rejectEmployee(
    RejectEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is LoadedEmployeeState) {
      _employeeRepository.removeEmployee(event.employee);
      emit(LoadedEmployeeState(_employeeRepository.getAllEmployees()));
    }
  }

  List<UnhiredEmployee> employeeToUnhired(
    List<Employee> employees,
    Location location,
  ) {
    return employees
        .map(
          (e) => UnhiredEmployee.fromEmployee(
            e,
            location,
            getEmployeeSkills(e),
          ),
        )
        .toList();
  }

  void _fireEmployee(
    FireEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) {
    if (state is LoadedEmployeeState) {
      if (_userRepository.getBalance() < event.employee.fireCost) {
        return;
      }
      _userRepository.userStreamController
          .add(DecreaseUserBalanceEvent(event.employee.fireCost.toDouble()));
      _alertRepository.alertStreamController.add(
          PushAlertEvent(employeeFiredAlert(event.employee, event.location)));
      _employeeRepository.fireEmployee(event.employee);
      emit(LoadedEmployeeState(_employeeRepository.getAllEmployees()));
    }
  }
}
