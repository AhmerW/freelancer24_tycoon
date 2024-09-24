import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/employees/employee_bloc.dart';
import 'package:freelancer24_tycoon/blocs/locations/location_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_offers_view.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EmployeesView extends StatefulWidget {
  final Location location;
  final Function() callback;
  const EmployeesView(
    this.location, {
    super.key,
    required this.callback,
  });

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  bool _offersView = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<EmployeeBloc, EmployeeState>(
              builder: (context, state) {
                if (state is LoadedEmployeeState) {
                  EmployeeBloc employeeBloc =
                      BlocProvider.of<EmployeeBloc>(context);
                  List<Employee> hiredEmployees =
                      state.getHiredEmployees(widget.location.id);

                  return AnimatedSwitcher(
                    duration: 200.ms,
                    key: UniqueKey(),
                    child: Column(
                      key: UniqueKey(),
                      children: [
                        _offersView
                            ? const SizedBox.shrink()
                            : Container(
                                key: UniqueKey(),
                                padding: EdgeInsets.zero,
                                height: 20,
                                child: Text(
                                    "Employees ${hiredEmployees.length} / ${widget.location.maxEmployees}"),
                              ),
                        Expanded(
                          key: UniqueKey(),
                          child: _offersView
                              ? EmployeeOffersView(
                                  key: UniqueKey(),
                                  employeeBloc.getUnhiredEmployeesGenIfLess(
                                      widget.location),
                                  location: widget.location,
                                  emptyOffersCallback: () => setState(() {}),
                                )
                              : HiredEmployeesView(
                                  key: UniqueKey(),
                                  hiredEmployees,
                                  widget.location,
                                  offersCallback: () => setState(() {
                                    _offersView = true;
                                  }),
                                ),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: Text("Employees not loaded"),
                );
              },
            ),
          ),
          Container(
              alignment: Alignment.bottomCenter,
              height: 50,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                  ),
                  const Spacer(),
                  TextButton(
                    child: _offersView
                        ? const Text("Manage your employees")
                        : const Text("Go back"),
                    onPressed: () {
                      if (_offersView) {
                        setState(() {
                          _offersView = false;
                        });
                      } else {
                        widget.callback();
                      }
                    },
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  const Spacer(),
                ],
              ))
        ],
      ),
    );
  }
}

class HiredEmployeesView extends StatefulWidget {
  final List<Employee> employees;
  final Location location;
  final Function() offersCallback;

  const HiredEmployeesView(
    this.employees,
    this.location, {
    super.key,
    required this.offersCallback,
  });

  @override
  State<HiredEmployeesView> createState() => _HiredEmployeesViewState();
}

class _HiredEmployeesViewState extends State<HiredEmployeesView> {
  void _onFireCallback(Employee employee, int index) {
    setState(() {
      BlocProvider.of<EmployeeBloc>(context)
          .add(FireEmployeeEvent(employee, widget.location));
      widget.employees.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.location.maxEmployees,
          itemBuilder: (context, index) {
            if (index >= widget.employees.length) {
              if (widget.location.employeeSlots < index + 1) {
                return ListTile(
                  onTap: () {
                    setState(() {
                      BlocProvider.of<LocationBloc>(context)
                          .add(UnlockEmployeeSlotEvent(widget.location));
                    });
                  },
                  tileColor: Colors.grey,
                  title: Text(
                      "Unlock slot for ${dollarInt(widget.location.employeeSlotPrice)}"),
                  subtitle: const Text("Unlock employee slot"),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.4),
                    child: const Icon(Icons.person_add_disabled_outlined),
                  ),
                  trailing: const Icon(
                    Icons.lock_outline,
                    color: Colors.red,
                  ),
                );
              }
              return ListTile(
                onTap: widget.offersCallback,
                tileColor: Colors.grey,
                title: const Text("Empty slot"),
                subtitle: const Text("Hire an employee"),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.4),
                  child: const Icon(Icons.person_outline_outlined),
                ),
                trailing: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            Employee offer = widget.employees[index];
            return EmployeeView(
              offer,
              fireCallback: () => _onFireCallback(offer, index),
            );
          },
        ),
      ),
    );
  }
}
