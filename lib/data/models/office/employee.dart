import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';

enum EmployeePerks {
  time2x,
}

class Employee {
  final int id;
  final String name;
  final int age;
  final int cut;
  final int pay; // daily pay
  final int hireCost;
  final int locationId;
  final int fireCost;
  bool hired;
  int? assignedTo;

  bool get isAssigned => assignedTo != null;

  List<SkillRequirementId> skills = [];

  Employee({
    required this.id,
    required this.name,
    required this.age,
    required this.cut,
    required this.pay,
    required this.locationId,
    required this.hireCost,
    required this.fireCost,
    this.assignedTo,
    this.skills = const [],
    this.hired = false,
  });

  @override
  String toString() {
    return 'Employee{id: $id, name: $name, age: $age, cut: $cut, pay: $pay, assignedTo: $assignedTo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Employee && other.id == id;
  }

  bool get isFreelancer => id == 0;
  bool hasSkill(int id) => skills.any((element) => element.skillId == id);

  factory Employee.freelancer() {
    return Employee(
      id: 0,
      name: "You",
      age: 0,
      cut: 0,
      pay: 0,
      locationId: 0,
      hireCost: 0,
      fireCost: 0,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'],
      age: json['age'],
      cut: json['cut'],
      pay: json['pay'],
      hireCost: json['hireCost'],
      assignedTo: json['assignedTo'],
      locationId: json['locationId'],
      hired: json['hired'] ?? false,
      fireCost: json['fireCost'] ?? 0,
      skills: (json['skills'] as List<dynamic>)
          .map((e) => SkillRequirementId.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'cut': cut,
      'pay': pay,
      'assignedTo': assignedTo,
      'skills': skills.map((e) => e.toJson()).toList(),
      'locationId': locationId,
      'hired': hired,
      'hireCost': hireCost,
      'fireCost': fireCost,
    };
  }
}

class UnhiredEmployee extends Employee {
  final Location location;
  List<Skill> skillObjects;

  List<Skill> get allSkillObjects => skillObjects;

  UnhiredEmployee({
    required super.id,
    required super.name,
    required super.age,
    required super.cut,
    required super.pay,
    required super.hireCost,
    required super.locationId,
    required super.hired,
    required super.fireCost,
    required this.location,
    this.skillObjects = const [],
  });

  Employee toEmployee() {
    return Employee(
      id: id,
      name: name,
      age: age,
      cut: cut,
      pay: pay,
      hireCost: hireCost,
      locationId: locationId,
      hired: hired,
      skills: skills,
      fireCost: fireCost,
    );
  }

  factory UnhiredEmployee.fromEmployee(
    Employee employee,
    Location location,
    List<Skill> skills,
  ) {
    return UnhiredEmployee(
      id: employee.id,
      name: employee.name,
      age: employee.age,
      cut: employee.cut,
      pay: employee.pay,
      hireCost: employee.hireCost,
      locationId: employee.locationId,
      hired: employee.hired,
      location: location,
      skillObjects: skills,
      fireCost: employee.fireCost,
    );
  }
}
