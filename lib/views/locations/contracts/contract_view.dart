import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/employees/employee_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shimmer/shimmer.dart';

class ContractView extends StatefulWidget {
  final Contract contract;
  final Location location;
  final Function() onCancel;
  const ContractView(this.contract, this.location,
      {super.key, required this.onCancel});

  @override
  State<ContractView> createState() => _ContractViewState();
}

class _ContractViewState extends State<ContractView> {
  String timeToFinish = "";
  Color? color;
  @override
  void initState() {
    super.initState();
    if (color == null) {
      setState(() {
        color = getRandomColor();
      });
    }
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.contract.isFinished) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          var t = widget.contract.timeToFinishFromNow();
          if (t == null) return;
          timeToFinish =
              "${t.inHours} hours ${t.inMinutes.remainder(60)} minutes and ${t.inSeconds.remainder(60)} seconds";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      height: 150,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.topCenter,
      child: Container(
        child: AnimatedSwitcher(
          duration: 200.ms,
          child: !widget.contract.isFinished && timeToFinish.isEmpty
              ? ShimmeredListTile(
                  key: UniqueKey(),
                )
              : 1 == 1
                  ? Column(
                      children: [
                        ListTile(
                          leading: RandomAvatar(
                            widget.contract.name,
                            trBackground: true,
                            width: 50,
                            height: 50,
                          ),
                          title: Text(
                            "Contract with ${widget.contract.name}",
                            style: TextStyle(
                              fontSize: 17.sp,
                            ),
                          ),
                          subtitle: widget.contract.acceptedAt == null
                              ? const SizedBox.shrink()
                              : widget.contract.isFinished
                                  ? const Text("Finished")
                                  : timeToFinish.isEmpty
                                      ? Container(
                                          alignment: Alignment.center,
                                          child:
                                              const CircularProgressIndicator(),
                                        )
                                      : Text("Finishes in $timeToFinish"),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              widget.onCancel();
                            },
                            child: Text(widget.contract.isFinished
                                ? "Collect pay"
                                : "Cancel contract")),
                      ],
                    )
                  : Column(
                      key: UniqueKey(),
                      children: [
                        Text(
                          "Contract with ${widget.contract.name}",
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18.sp,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 100,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: CircleAvatar(
                                backgroundColor: color,
                                child: RandomAvatar(
                                  widget.contract.name,
                                  width: 50,
                                  height: 50,
                                  trBackground: true,
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: 200.ms,
                              child: widget.contract.acceptedAt == null
                                  ? const SizedBox.shrink()
                                  : widget.contract.isFinished
                                      ? const Text("Finished")
                                      : timeToFinish.isEmpty
                                          ? Container(
                                              alignment: Alignment.center,
                                              child:
                                                  const CircularProgressIndicator(),
                                            )
                                          : Text("Finishes in $timeToFinish"),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 80,
                          child: Builder(builder: (context) {
                            List<Employee> employees =
                                BlocProvider.of<EmployeeBloc>(context)
                                    .getEmployeeFromIds(widget.location,
                                        widget.contract.assignedTo);

                            return SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  for (Employee employee in employees) ...[
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircleAvatar(
                                        backgroundColor: color,
                                        child: employee.isFreelancer
                                            ? const Icon(Icons.person_outline)
                                            : RandomAvatar(
                                                employee.name,
                                                width: 50,
                                                height: 50,
                                                trBackground: true,
                                              ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          }),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.onCancel();
                          },
                          child: widget.contract.isFinished
                              ? const Text("Collect pay")
                              : const Text("Cancel contrarct"),
                        )
                      ],
                    ),
        ),
      ),
    );
  }
}

class ShimmeredListTile extends StatelessWidget {
  const ShimmeredListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 100.w,
        height: 100.0,
        child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              title: Container(
                height: 20,
                width: 100.w,
                color: Colors.white,
              ),
              leading: const CircleAvatar(),
            )));
  }
}
