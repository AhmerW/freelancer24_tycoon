import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/skills/skill_bloc.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/widgets/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillsView extends StatefulWidget {
  static const int lockedSkillsView = 5;

  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SkillsBloc, SkillState>(builder: (context, state) {
        if (state is SkillsLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is SkillsLoaded) {
          SkillsBloc skillsBloc =
              BlocProvider.of<SkillsBloc>(context, listen: true);
          List<Skill> nextN = skillsBloc.getNextNLockedSkills(
            state.skills,
            SkillsView.lockedSkillsView,
          );
          List<Skill> skills = state.skills + nextN;
          return Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Text(
                "Skills (${state.skills.length})",
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              skills.isEmpty
                  ? const Text("error")
                  : Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          var skillWidgets = skills
                              .map((skill) => SizedBox(
                                    height: 300,
                                    width: 300,
                                    child: SkillWidget(
                                      skill: skill,
                                      isFirst: skill.id ==
                                          (skills.length) - nextN.length,
                                      previous: skill.id == 0
                                          ? null
                                          : skills[skill.id - 1],
                                    ),
                                  ))
                              .toList();
                          if (constraints.maxWidth > 600) {
                            return GridView.count(
                                crossAxisCount: responsiveCrossAxisCount(
                                  constraints.maxWidth,
                                ),
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                scrollDirection: Axis.vertical,
                                children: skillWidgets);
                          } else {
                            return ListView(
                              scrollDirection: Axis.vertical,
                              children: skillWidgets,
                            );
                          }
                        },
                      ),
                    ),
            ],
          );
        } else {
          return const Center(
            child: Text("Error loading skills"),
          );
        }
      }),
    );
  }
}
