import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/contracts/contract_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/contract_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ContractsView extends StatefulWidget {
  final List<Contract> contracts;
  final Location location;
  final bool onlyOffers;
  final bool onlyContracts;
  final Function() callback;
  const ContractsView(
    this.contracts,
    this.location, {
    super.key,
    this.onlyOffers = false,
    this.onlyContracts = false,
    required this.callback,
  });

  @override
  State<ContractsView> createState() => _ContractsViewState();
}

class _ContractsViewState extends State<ContractsView> {
  void onCancel(Contract contract, int index) {
    setState(() {
      BlocProvider.of<ContractBloc>(context).add(CancelContractEvent(contract));
      widget.contracts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.h,
      child: Column(
        children: [
          Flexible(
            flex: 9, // Set a specific height
            child: widget.contracts.isEmpty
                ? const Center(
                    child: Text("You have no active contracts"),
                  )
                : ListView.builder(
                    itemCount: widget.contracts.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      Contract contract = widget.contracts[index];
                      return ContractView(
                        contract,
                        widget.location,
                        onCancel: () => onCancel(contract, index),
                      );
                    },
                  ),
          ),
          Flexible(
            flex: 1,
            child: TextButton(
              onPressed: widget.callback,
              child: const Text("Go back"),
            ),
          ),
        ],
      ),
    );
  }
}
