part of "employee_bloc.dart";

class EmployeeState extends Equatable {
  const EmployeeState();

  @override
  List<Object?> get props => [];
}

class LoadedEmployeeState extends EmployeeState {
  final Map<int, List<Employee>> employees;

  const LoadedEmployeeState(this.employees);

  List<Employee> withFreelancer(List<Employee> data) =>
      [Employee.freelancer()] + data;

  int hiredEmployeesCount(int locationId) =>
      getHiredEmployees(locationId).length;

  List<Employee> getHiredEmployees(int locationId) {
    List<Employee> es = employees[locationId] ?? [];
    return es.where((e) => e.hired).toList();
  }

  List<Employee> getUnhiredEmployees(int locationId) {
    List<Employee> es = employees[locationId] ?? [];
    return es.where((e) => !e.hired).toList();
  }

  LoadedEmployeeState.copyWith({
    Map<int, List<Employee>>? employees,
  }) : employees = employees ?? {};

  const LoadedEmployeeState.empty() : employees = const {};

  @override
  List<Object?> get props => [employees];
}
