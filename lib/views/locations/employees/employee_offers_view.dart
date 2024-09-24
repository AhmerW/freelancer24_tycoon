import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/employees/employee_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_offer_view.dart';

class EmployeeOffersView extends StatefulWidget {
  final List<UnhiredEmployee> unhiredEmployees;
  final Location location;
  final Function() emptyOffersCallback;
  const EmployeeOffersView(
    this.unhiredEmployees, {
    super.key,
    required this.location,
    required this.emptyOffersCallback,
  });

  @override
  State<EmployeeOffersView> createState() => _EmployeeOffersViewState();
}

class _EmployeeOffersViewState extends State<EmployeeOffersView> {
  bool loadingOffers = true;
  bool loadingAfterEmpty = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          loadingOffers = false;
        });
      }
    });
  }

  void _hireEmployee(Employee employee, int index) {
    setState(() {
      BlocProvider.of<EmployeeBloc>(context).add(HireEmployeeEvent(
        employee,
        widget.location,
      ));
      widget.unhiredEmployees.removeAt(index);
    });
  }

  void _rejectEmployee(Employee employee, int index) {
    setState(() {
      BlocProvider.of<EmployeeBloc>(context).add(RejectEmployeeEvent(
        employee,
        widget.location,
      ));
      widget.unhiredEmployees.removeAt(index);
      if (widget.unhiredEmployees.isEmpty) {
        // wait 5 seconds before regenerating offers
        loadingOffers = true;
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            loadingOffers = false;
          });
          widget.emptyOffersCallback();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: loadingOffers
          ? Center(
              child: Column(
                children: [
                  Text(loadingAfterEmpty
                      ? "Getting more offers"
                      : "Loading offers"),
                  const SizedBox(
                    height: 10,
                  ),
                  const CircularProgressIndicator()
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: widget.unhiredEmployees.length,
              itemBuilder: (context, index) {
                UnhiredEmployee offer = widget.unhiredEmployees[index];
                return EmployeeOfferView(offer,
                    location: widget.location,
                    hireCallback: () => _hireEmployee(offer, index),
                    rejectCallback: () => _rejectEmployee(offer, index));
              },
            ),
    );
  }
}
