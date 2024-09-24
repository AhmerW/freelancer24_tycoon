import 'dart:convert';

import 'package:freelancer24_tycoon/data/models/office/employee.dart';

import 'package:hive/hive.dart';

class EmployeeRepository {
  final Map<int, List<Employee>> _allEmployees = {};

  EmployeeRepository();

  List<Employee> getHiredEmployees(int locationId) {
    List<Employee> employees = getEmployees(locationId);
    return employees.where((e) => e.hired).toList();
  }

  List<Employee> getUnhiredEmployees(int locationId) {
    List<Employee> employees = getEmployees(locationId);
    return employees.where((e) => !e.hired).toList();
  }

  Map<int, List<Employee>> getAllEmployees() {
    if (_allEmployees.isNotEmpty) {
      return _allEmployees;
    }
    var box = Hive.box("employees");

    for (var e in box.values) {
      Employee employee = Employee.fromJson(jsonDecode(e));
      if (!_allEmployees.containsKey(employee.locationId)) {
        _allEmployees[employee.locationId] = [];
      }
      _allEmployees[employee.locationId]!.add(employee);
    }
    return _allEmployees;
  }

  List<Employee> getEmployees(int locationId) {
    if (_allEmployees.containsKey(locationId)) {
      return _allEmployees[locationId]!;
    }
    getAllEmployees();
    if (!_allEmployees.containsKey(locationId)) {
      _allEmployees[locationId] = [];
    }
    return _allEmployees[locationId]!;
  }

  Box getEmployeeLocationBox(int locationId) {
    // ensure allEmployees contains array for location employees
    var box = Hive.box("employees");

    if (!_allEmployees.containsKey(locationId)) {
      getEmployees(locationId);
    }
    return box;
  }

  void addEmployee(Employee employee) {
    var box = getEmployeeLocationBox(employee.locationId);
    _allEmployees[employee.locationId]!.add(employee);
    box.put(employee.id, jsonEncode(employee.toJson()));
  }

  void removeEmployee(Employee employee) {
    var box = getEmployeeLocationBox(employee.locationId);
    box.delete(employee.id);
    _allEmployees[employee.locationId]!
        .removeWhere((element) => element.id == employee.id);
  }

  void hireEmployee(Employee employee) {
    removeEmployee(employee);
    employee.hired = true;
    addEmployee(employee);
  }

  void fireEmployee(Employee employee) {
    removeEmployee(employee);
  }
}
