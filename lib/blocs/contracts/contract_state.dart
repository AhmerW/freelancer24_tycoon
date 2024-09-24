part of "contract_bloc.dart";

class ContractState extends Equatable {
  const ContractState();

  @override
  List<Object> get props => [];
}

class LoadedContractState extends ContractState {
  final Map<int, List<Contract>> contracts;

  const LoadedContractState(this.contracts);

  LoadedContractState.copyWith({
    Map<int, List<Contract>>? contracts,
  }) : contracts = contracts ?? {};

  const LoadedContractState.empty() : contracts = const {};

  @override
  List<Object> get props => [contracts];
}
