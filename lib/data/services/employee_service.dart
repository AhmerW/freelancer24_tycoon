import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/employee_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';

class EmployeeService {
  final EmployeeRepository _employeeRepository;
  final SkillRepository _skillRepository;

  EmployeeService(
    this._employeeRepository,
    this._skillRepository,
  );

  Employee generateEmployee(
    Location location,
  ) {
    final int id = UniqueKey().hashCode;
    String name = location.names[Random().nextInt(location.names.length)];
    int age = randomRange(18, 60);
    int cut = randomRange(1, 30);
    int pay = randomRange(1, 50) * 100;
    int hireCost = Random().nextInt(100) + 50;
    int fireCost = Random().nextInt(100) + 50;

    List<int> skillsIds = _skillRepository
        .generateNRandomUnlockedSkills(3)
        .map((e) => e.id)
        .toList();

    List<SkillRequirementId> skills = skillsIds
        .map((e) => SkillRequirementId(
              skillId: e,
              level: Random().nextInt(5) + 1,
            ))
        .toList();

    return Employee(
      id: id,
      name: name,
      age: age,
      cut: cut,
      pay: pay,
      locationId: location.id,
      hired: false,
      hireCost: hireCost,
      skills: skills,
      fireCost: fireCost,
    );
  }

  List<Employee> getUnhiredEmployeesGenIfLess(
    Location location,
    SkillRepository skillRepository,
  ) {
    List<Employee> unhired =
        _employeeRepository.getUnhiredEmployees(location.id);
    // run maxEmployees time times

    if (unhired.length <= location.maxEmployees) {
      for (int i = 0; i < location.maxEmployees; i++) {
        if (unhired.length >= location.maxEmployees) {
          break;
        }
        Employee employee = generateEmployee(location);
        if (unhired
            .where((element) => element.name == employee.name)
            .isNotEmpty) {
          continue;
        }

        _employeeRepository.addEmployee(employee);
        unhired.add(employee);
      }
    }
    return unhired;
  }
}
