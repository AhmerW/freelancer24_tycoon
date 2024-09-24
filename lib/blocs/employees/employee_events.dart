part of "employee_bloc.dart";

class EmployeeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEmployeesEvent extends EmployeeEvent {}

class HireEmployeeEvent extends EmployeeEvent {
  final Employee employee;
  final Location location;

  HireEmployeeEvent(this.employee, this.location);

  @override
  List<Object?> get props => [employee, location];
}

class RejectEmployeeEvent extends EmployeeEvent {
  final Employee employee;
  final Location location;

  RejectEmployeeEvent(this.employee, this.location);

  @override
  List<Object?> get props => [employee, location];
}

class FireEmployeeEvent extends EmployeeEvent {
  final Employee employee;
  final Location location;

  FireEmployeeEvent(this.employee, this.location);

  @override
  List<Object?> get props => [employee, location];
}
