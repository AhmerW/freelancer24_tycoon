import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/contracts/contract_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/offer_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class OffersView extends StatefulWidget {
  final Location location;
  final List<Contract> contracts;
  final bool onlyOffers;
  final bool onlyContracts;
  final Function() callback;
  final Function() callbackContracts;
  final Function() onReject;
  const OffersView(
    this.location,
    this.contracts, {
    super.key,
    this.onlyOffers = false,
    this.onlyContracts = false,
    required this.callback,
    required this.callbackContracts,
    required this.onReject, // regenerates offers
  });

  @override
  State<OffersView> createState() => _ContractsViewState();
}

class _ContractsViewState extends State<OffersView> {
  bool regenerating = false;
  List<int> accepted = [];

  void onRemove(Contract contract, int index) {
    setState(() {
      BlocProvider.of<ContractBloc>(context)
          .add(RejectContractEvent(contract, widget.location));
      widget.contracts.removeAt(index);
    });
  }

  void onAccept(Contract contract, List<Employee> employees) {
    setState(() {
      BlocProvider.of<ContractBloc>(context)
          .add(AcceptContractEvent(contract, widget.location, employees));

      if (contract.accepted) accepted.add(contract.id);
    });
  }

  @override
  void initState() {
    super.initState();
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
                ? Center(
                    child: regenerating
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("Finding new offers..."),
                              SizedBox(
                                height: 5,
                              ),
                              CircularProgressIndicator()
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            child: const Text(
                                "No offers found. Run marketing campaign or finish existing offers to expand your reach."),
                          ),
                  )
                : ListView.builder(
                    itemCount: widget.contracts.length,
                    itemBuilder: (context, index) {
                      Contract offer = widget.contracts[index];
                      if (accepted.contains(offer.id) || offer.accepted) {
                        return Container(
                          height: 50,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ListTile(
                            onTap: widget.callbackContracts,
                            title: Text(
                              "Contract with ${offer.name} accepted",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 18.sp,
                              ),
                            ),
                            subtitle: Text(
                              "Click to view contract details",
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 15.sp,
                              ),
                            ),
                            leading: const Icon(
                              Icons.check,
                              size: 20,
                            ),
                          ),
                        );
                      }
                      return OfferView(
                        offer,
                        widget.location,
                        onRemove: () {
                          onRemove(offer, index);
                          if (widget.contracts.isEmpty) {
                            setState(() {
                              regenerating = true;
                            });
                            Future.delayed(
                                const Duration(
                                  seconds: 2,
                                ), () {
                              regenerating = false;
                              widget.onReject();
                            });
                          }
                        },
                        onAccept: (employees) => onAccept(offer, employees),
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
