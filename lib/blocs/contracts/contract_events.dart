part of "contract_bloc.dart";

class ContractEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class AcceptContractEvent extends ContractEvent {
  final Contract offer;
  final Location location;
  final List<Employee> assignedTo;

  AcceptContractEvent(this.offer, this.location, this.assignedTo);

  @override
  List<Object> get props => [offer, location, assignedTo];
}

class RejectContractEvent extends ContractEvent {
  final Contract offer;
  final Location location;

  RejectContractEvent(this.offer, this.location);

  @override
  List<Object> get props => [offer, location];
}

class CancelContractEvent extends ContractEvent {
  final Contract contract;

  CancelContractEvent(this.contract);

  @override
  List<Object> get props => [contract];
}

class LoadContracsEvent extends ContractEvent {}
