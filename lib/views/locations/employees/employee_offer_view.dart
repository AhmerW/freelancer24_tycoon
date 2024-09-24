import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EmployeeOfferView extends StatefulWidget {
  final UnhiredEmployee employee;
  final Location location;
  final Function() hireCallback;
  final Function() rejectCallback;
  const EmployeeOfferView(
    this.employee, {
    super.key,
    required this.hireCallback,
    required this.rejectCallback,
    required this.location,
  });

  @override
  State<EmployeeOfferView> createState() => _EmployeeOfferViewState();
}

class _EmployeeOfferViewState extends State<EmployeeOfferView> {
  Color? color;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    if (color == null) {
      setState(() {
        color = getRandomDarkColor();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var employee = widget.employee;
    return Column(
      children: [
        Card(
          elevation: 2.0,
          borderOnForeground: true,
          shape: const RoundedRectangleBorder(
            // only bottom borderside

            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedSize(
              duration: 200.ms,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                      ListTile(
                        leading: SizedBox(
                          width: 70,
                          height: 70,
                          child: CircleAvatar(
                            backgroundColor: color,
                            child: RandomAvatar(
                              employee.name,
                              width: 70,
                              height: 70,
                              trBackground: true,
                            ),
                          ),
                        ),
                        title: Text(
                          employee.name,
                          style: GoogleFonts.robotoCondensed(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        subtitle: Text(
                          'Age: ${employee.age} (${DateTime.now().year - employee.age})',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 15.sp,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ID: ${employee.id}'),
                            Text('Location: ${widget.location.city}'),
                          ],
                        ),
                      ),
                      _hidden
                          ? Center(
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hidden = false;
                                  });
                                },
                                icon: const Icon(
                                    Icons.expand_circle_down_outlined),
                              ),
                            )
                          : const SizedBox.shrink()
                    ] +
                    (_hidden == true
                        ? <Widget>[]
                        : <Widget>[
                            SizedBox(
                              width: 100.w,
                              height: 50,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      height: 20,
                                      indent: 20,
                                      endIndent: 20,
                                      color: color,
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _hidden = true;
                                        });
                                      },
                                      icon: const Icon(Icons.close_outlined))
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        OfferLabel(
                                          icon: Icons.payments_outlined,
                                          color: color ?? Colors.green,
                                          text: "Daily pay: ",
                                          value: "${r'$'}${employee.pay}",
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        OfferLabel(
                                          icon: Icons.receipt_long_outlined,
                                          color: color ?? Colors.green,
                                          text: "Hire cost: ",
                                          value: "${r'$'}${employee.hireCost}",
                                        ),
                                      ],
                                    ),
                                    const VerticalDivider(
                                      width: 5,
                                    ),
                                    Column(
                                      children: [
                                        OfferLabel(
                                          icon: Icons.percent_rounded,
                                          color: color ?? Colors.green,
                                          text: "Cut per contract: ",
                                          value: "${employee.cut}%",
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        OfferLabel(
                                          icon: Icons.remove_circle_outline,
                                          color: Colors.black,
                                          text: "Termination cost: ",
                                          value: "${r'$'}${employee.fireCost}",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                EmployeeOfferSkillsView(
                                  employee,
                                  color ?? Colors.black,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Divider(
                                  indent: 20,
                                  endIndent: 20,
                                  color: color,
                                ),
                                Container(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: SizedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        SizedBox(
                                          width: 30.w,
                                          child: TextButton(
                                            onPressed: widget.rejectCallback,
                                            style: ButtonStyle(
                                                shape: WidgetStateProperty.all<
                                                    RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side: const BorderSide(
                                                    color: Colors.black,
                                                  )),
                                            )),
                                            child: Text(
                                              "Reject ${employee.name}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40.w,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              widget.hireCallback();
                                              // show snackbar
                                            },
                                            child: Text(
                                              "Hire ${employee.name} for ${r'$'}${employee.hireCost}",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OfferLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String value;
  const OfferLabel({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5),
      width: 40.w,
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: color,
          ),
          const SizedBox(
            width: 7,
          ),
          RichText(
              text: TextSpan(
                  text: text,
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 16.sp,
                  ),
                ),
              ])),
        ],
      ),
    );
  }
}

class EmployeeOfferSkillsView extends StatelessWidget {
  final UnhiredEmployee employee;
  final Color color;
  const EmployeeOfferSkillsView(this.employee, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: employee.skillObjects.length,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Chip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: color),
                      ),
                      label: Text(
                          "${employee.skillObjects[index].name} lvl ${employee.skillObjects[index].level}"),
                    ),
                  );
                })),
          ),
        ],
      ),
    );
  }
}
