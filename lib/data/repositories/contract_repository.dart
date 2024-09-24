import 'dart:convert';

import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:hive/hive.dart';

class ContractRepository {
  // Location.id<->List<Contract>
  final Map<int, List<Contract>> _contractsMap = {};
  bool fetched = false;

  ContractRepository();

  List<Contract> getContracts(Location location) {
    var contractsMap = getAllContracts();
    if (contractsMap.containsKey(location.id)) {
      return contractsMap[location.id]!;
    }

    return [];
  }

  void addContract(Contract contract, Location location) {
    if (!_contractsMap.containsKey(location.id)) {
      _contractsMap[location.id] = [];
    }
    _contractsMap[location.id]!.add(contract);
    Hive.box("contracts").put(contract.id, jsonEncode(contract));
  }

  void acceptContract(Contract contract, Location location) {
    getAllContracts();
    removeContract(contract);
    contract.accepted = true;
    contract.acceptedAt = DateTime.now();
    addContract(contract, location);
  }

  void removeContract(Contract contract) {
    Hive.box("contracts").delete(contract.id);
    if (_contractsMap.containsKey(contract.location)) {
      _contractsMap[contract.location]!
          .removeWhere((element) => element.id == contract.id);
    }
  }

  void cancelContract(Contract contract) {
    // its the same no
    removeContract(contract);
  }

  Map<int, List<Contract>> getAllContracts() {
    // gets both offers and contracts (differensiated by accepted/active = false/true) if accepted, its active.
    if (fetched) {
      return _contractsMap;
    }
    var contractBox = Hive.box("contracts");
    contractBox.clear();
    for (var contract in contractBox.values) {
      Contract c = Contract.fromJson(jsonDecode(contract));

      if (!_contractsMap.containsKey(c.location)) {
        _contractsMap[c.location] = [];
      }
      _contractsMap[c.location]!.add(c);
    }
    fetched = true;

    return _contractsMap;
  }
}
