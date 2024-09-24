import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/contracts/contract_bloc.dart';
import 'package:freelancer24_tycoon/blocs/employees/employee_bloc.dart';
import 'package:freelancer24_tycoon/blocs/skills/skill_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class OfferView extends StatefulWidget {
  final Contract offer;
  final Location location;
  final Function() onRemove;
  final Function(List<Employee>) onAccept;
  const OfferView(
    this.offer,
    this.location, {
    super.key,
    required this.onRemove,
    required this.onAccept,
  });

  @override
  State<OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends State<OfferView> {
  Color color = Colors.orange;
  Set<int> selected = {};
  bool _hidden = true;
  bool _acceptable = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SkillsBloc skillsBloc = BlocProvider.of<SkillsBloc>(context);
    return Container(
      width: 80.w,
      decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: Colors.black.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
          color: Colors.white.withOpacity(0.4)),
      child:
          BlocBuilder<ContractBloc, ContractState>(builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    width: 100.w,
                    height: 120,
                    duration: 200.ms,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: null,
                      color: null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.topLeft,
                                child: Text(
                                    "${widget.offer.golden ? 'GOLDEN' : ''} Offer by ${widget.offer.name} from ${widget.location.city}",
                                    style: GoogleFonts.robotoCondensed(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: widget.offer.golden
                                            ? Colors.orange
                                            : null)),
                              ),
                              Container(
                                  alignment: Alignment.topLeft,
                                  padding: const EdgeInsets.only(left: 5),
                                  child: AnimatedTextKit(
                                    repeatForever: false,
                                    totalRepeatCount: 1,
                                    animatedTexts: [
                                      TyperAnimatedText(
                                        speed: 20.ms,
                                        widget.offer.message,
                                        textStyle: GoogleFonts.robotoCondensed(
                                            fontSize: 16.sp),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            RandomAvatar(widget.offer.name,
                                width: 70, height: 70, trBackground: true),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OfferLabel(
                                    icon: Icons.schedule_outlined,
                                    color: Colors.black,
                                    text:
                                        "${widget.offer.completionTime.inHours} hours and ${widget.offer.completionTime.inMinutes} minutes"),
                                OfferLabel(
                                    icon: Icons.payment_outlined,
                                    color: Colors.green,
                                    text:
                                        "${r'$'}${formatMoney(widget.offer.pay)}"),
                                OfferLabel(
                                    icon: Icons.bolt_outlined,
                                    color: Colors.orange,
                                    text: "${widget.offer.energy}%"),
                                OfferLabel(
                                    icon: Icons.people_outline,
                                    color: Colors.black,
                                    text:
                                        widget.offer.requiredPeople.toString())
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Divider(),
              AnimatedSize(
                duration: 200.ms,
                child: _hidden
                    ? Container(
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: const Icon(Icons.expand_circle_down_outlined),
                          onPressed: () {
                            setState(() {
                              _hidden = !_hidden;
                            });
                          },
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(left: 10),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Required skills (${widget.offer.requiredSkills.length}):",
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _hidden = !_hidden;
                                        });
                                      },
                                      icon: const Icon(Icons.close))),
                            ],
                          ),
                          SizedBox(
                            height: 60,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (var skill in widget.offer.requiredSkills)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Builder(builder: (context) {
                                      Skill? s = skillsBloc
                                          .hasUnlockedSkill(skill.skill);
                                      return Chip(
                                          side: BorderSide(
                                            color: s == null
                                                ? Colors.red
                                                : s.level >= skill.level
                                                    ? Colors.green
                                                    : Colors.red,
                                            width: 1,
                                          ),
                                          label: Column(
                                            children: [
                                              Text(
                                                  "${skill.skill.name} (level ${skill.level})",
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  )),
                                              s != null
                                                  ? RichText(
                                                      text: TextSpan(children: [
                                                      TextSpan(
                                                          text: "Unlocked ",
                                                          style: GoogleFonts
                                                              .roboto(
                                                            color: Colors.black,
                                                            fontSize: 14,
                                                          )),
                                                      TextSpan(
                                                          text:
                                                              "(level ${s.level})",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: s.level >=
                                                                      skill
                                                                          .level
                                                                  ? Colors.green
                                                                  : Colors.red))
                                                    ]))
                                                  : const Text(
                                                      "Not unlocked",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                            ],
                                          ));
                                    }),
                                  )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                              height: 80,
                              child: Column(
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      "Assign to ${widget.offer.requiredPeople} employee${widget.offer.requiredPeople > 1 ? 's' : ''}:",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.robotoCondensed(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17.sp,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: BlocBuilder<EmployeeBloc,
                                        EmployeeState>(
                                      builder: (context, state) {
                                        if (state is LoadedEmployeeState) {
                                          List<Employee> employees =
                                              state.withFreelancer(
                                                  state.getHiredEmployees(
                                                      widget.location.id));
                                          int unassigned = employees
                                              .where((e) => !e.isAssigned)
                                              .length;
                                          if (widget.offer.requiredPeople >
                                              employees.length) {
                                            _acceptable = false;
                                            return Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(20),
                                              child: Text(
                                                "You dont' have enough employees to assign to this offer! Required: ${widget.offer.requiredPeople}, available: ${employees.length}",
                                              ),
                                            );
                                          }
                                          if (unassigned <
                                              widget.offer.requiredPeople) {
                                            _acceptable = false;
                                            if (_acceptable == false) {
                                              _acceptable = true;
                                            }
                                            return Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                "This offer requires ${widget.offer.requiredPeople} employees, but you have only $unassigned available",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 17.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }
                                          return Container(
                                            alignment: Alignment.center,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              shrinkWrap: true,
                                              itemCount: employees.length,
                                              itemBuilder: (context, index) {
                                                Employee employee =
                                                    employees[index];
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: ChoiceChip(
                                                      elevation: 10,
                                                      selected: selected
                                                          .contains(index),
                                                      onSelected: (value) {
                                                        setState(() {
                                                          if (selected.length >=
                                                                  widget.offer
                                                                      .requiredPeople ||
                                                              selected.contains(
                                                                  index)) {
                                                            selected
                                                                .remove(index);
                                                          } else {
                                                            selected.add(index);
                                                          }
                                                        });
                                                      },
                                                      label: Row(
                                                        children: [
                                                          employee.isFreelancer
                                                              ? const Icon(
                                                                  Icons
                                                                      .person_outline,
                                                                  size: 30,
                                                                )
                                                              : RandomAvatar(
                                                                  employee.name,
                                                                  width: 30,
                                                                  height: 30),
                                                          Container(
                                                            color: employee
                                                                    .isAssigned
                                                                ? Colors.red
                                                                : null,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        5),
                                                            child: Text(
                                                                employee.name),
                                                          ),
                                                        ],
                                                      )),
                                                );
                                              },
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ],
                              )),
                          const SizedBox(
                            height: 15,
                          ),
                          SizedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width: 30.w,
                                  child: TextButton(
                                    onPressed: widget.onRemove,
                                    style: ButtonStyle(
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side: const BorderSide(
                                            color: Colors.red,
                                          )),
                                    )),
                                    child: const Text(
                                      "Reject",
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: 30.w,
                                    child: BlocBuilder<EmployeeBloc,
                                        EmployeeState>(
                                      builder: (context, state) {
                                        if (state is LoadedEmployeeState) {
                                          List<Employee> employees =
                                              state.withFreelancer(
                                                  state.getHiredEmployees(
                                                      widget.location.id));
                                          return ElevatedButton(
                                            onPressed: _acceptable
                                                ? () {
                                                    if (selected.length !=
                                                        widget.offer
                                                            .requiredPeople) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            "You need to assign ${widget.offer.requiredPeople} employees to this offer!"),
                                                        duration: 2.seconds,
                                                      ));
                                                      return;
                                                    } else {
                                                      List<Employee>
                                                          selectedEmployees =
                                                          selected
                                                              .map((e) =>
                                                                  employees[e])
                                                              .toList();

                                                      widget.onAccept(
                                                          selectedEmployees);
                                                    }
                                                  }
                                                : null,
                                            child: const Text("Accept"),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class OfferLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const OfferLabel({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
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
          Text(
            text,
            style: GoogleFonts.robotoCondensed(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
