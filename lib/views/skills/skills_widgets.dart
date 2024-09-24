import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/skills/skill_bloc.dart';
import 'package:freelancer24_tycoon/data/models/skills/skill.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_animate/flutter_animate.dart';

class SkillWidget extends StatefulWidget {
  final Skill skill;
  final Skill? previous;
  final bool isFirst;

  const SkillWidget({
    super.key,
    required this.skill,
    this.isFirst = false,
    this.previous,
  });

  @override
  _SkillWidget createState() => _SkillWidget();
}

class _SkillWidget extends State<SkillWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SkillsBloc skillsBloc = BlocProvider.of<SkillsBloc>(context);
    return ScaleTransition(
      scale: _animation,
      child: Animate(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: 500.ms,
                    padding: const EdgeInsets.only(top: 10),
                    alignment: Alignment.topCenter,
                    child: widget.skill.locked
                        ? const Text("LOCKED")
                        : Text(
                            widget.skill.name,
                            style: GoogleFonts.sansita(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      widget.skill.locked
                          ? widget.isFirst &&
                                  widget.previous != null &&
                                  widget.previous!.level <=
                                      widget.skill.unlockOnPreviousLevel
                              ? "Requires '${widget.previous!.name}' on level ${widget.skill.unlockOnPreviousLevel}"
                              : "Unlock previous skill first"
                          : widget.skill.description,
                      style: GoogleFonts.robotoCondensed(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: widget.skill.locked && widget.isFirst
                              ? Theme.of(context).primaryColor
                              : null),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          width: 50,
                          height: 50,
                          constraints:
                              const BoxConstraints(maxHeight: 50, maxWidth: 50),
                          margin: const EdgeInsets.only(left: 15),
                          child: Container(
                            alignment: Alignment.center,
                            child: widget.skill.locked
                                ? const SizedBox.shrink()
                                : Image.asset(
                                    "assets/icons/skills/${widget.skill.icon}",
                                    fit: BoxFit.fill,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            child: widget.skill.locked
                                ? widget.isFirst
                                    ? const SizedBox.shrink()
                                    : const Icon(
                                        Icons.question_mark,
                                        size: 30,
                                      )
                                : AnimatedTextKit(
                                    key: ValueKey<int>(widget.skill.level),
                                    repeatForever: false,
                                    totalRepeatCount:
                                        widget.skill.locked ? 0 : 1,
                                    pause: const Duration(milliseconds: 450),
                                    animatedTexts: [
                                      ColorizeAnimatedText(
                                        "Level ${widget.skill.level}",
                                        textStyle: GoogleFonts.robotoCondensed(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context).cardColor,
                                          Theme.of(context).dividerColor,
                                        ],
                                      )
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        )
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.only(bottom: 15),
                    child: TextButton(
                      onPressed: widget.skill.locked && !widget.isFirst
                          ? null
                          : () {
                              if (!widget.skill.locked) {
                                setState(() {
                                  skillsBloc
                                      .add(UpgradeSkillEvent(widget.skill));
                                });
                              } else {
                                setState(() {
                                  skillsBloc
                                      .add(UnlockNewSkillEvent(widget.skill));
                                });
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.skill.locked
                                ? "UNLOCK ${r"$"}${formatMoney(widget.skill.price)}"
                                : "UPGRADE ${r"$"}${formatMoney(skillsBloc.getUpgradePrice(widget.skill))}",
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          widget.skill.locked
                              ? const Icon(Icons.lock_outline)
                              : const Icon(
                                  Icons.keyboard_double_arrow_up_sharp,
                                  size: 30,
                                )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
