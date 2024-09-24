import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';

class Contract {
  final int id;
  final String name;
  final double pay;
  final int location;
  final Duration completionTime;
  final List<SkillRequirement> requiredSkills;
  final int requiredPeople;
  final String message;
  final bool golden;
  final int energy;

  bool accepted;
  DateTime? acceptedAt;
  List<int> assignedTo; // EMPLOYEE IDS

  Contract({
    required this.id,
    required this.name,
    required this.pay,
    required this.location,
    required this.completionTime,
    required this.requiredSkills,
    required this.requiredPeople,
    required this.message,
    required this.energy,
    this.accepted = false,
    this.golden = false,
    this.assignedTo = const [],
    this.acceptedAt,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      name: json['name'],
      pay: json['pay'],
      location: json['location'],
      completionTime: Duration(minutes: json['completionTime']),
      requiredSkills: (json['requiredSkills'] as List<dynamic>)
          .map((e) => SkillRequirement.fromJson(e))
          .toList(),
      requiredPeople: json['requiredPeople'],
      message: json['message'],
      accepted: json['accepted'] ?? false,
      golden: json['golden'] ?? false,
      energy: json['energy'] ?? 0,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      assignedTo:
          json['assignedTo'] != null ? List<int>.from(json['assignedTo']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pay': pay,
      'location': location,
      'completionTime': completionTime.inMinutes,
      'requiredSkills': requiredSkills.map((e) => e.toJson()).toList(),
      'requiredPeople': requiredPeople,
      'message': message,
      'accepted': accepted,
      'golden': golden,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'energy': energy,
      'assignedTo': assignedTo,
    };
  }

  bool doesEmployeeMatchSkill(Employee employee) {
    return requiredSkills
            .where((s) =>
                employee.hasSkill(s.skill.id) &&
                employee.skills[s.skill.id].level >= s.skill.level)
            .length ==
        requiredSkills.length;
  }

  DateTime? timeToFinish() {
    return acceptedAt?.add(completionTime);
  }

  Duration? timeToFinishFromNow() {
    return timeToFinish()?.difference(DateTime.now());
  }

  bool get isFinished => timeToFinishFromNow()?.isNegative ?? false;

  // overide eq
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Contract && other.id == id;
  }
}
