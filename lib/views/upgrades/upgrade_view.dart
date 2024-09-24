import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/upgrades/upgrade_bloc.dart';
import 'package:freelancer24_tycoon/data/models/upgrades/upgrade.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/views/widgets/energybar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class UpgradeView extends StatefulWidget {
  final UpgradeCategory category;
  final Color color;
  const UpgradeView(
    this.category, {
    super.key,
    required this.color,
  });

  @override
  State<UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<UpgradeView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: FlexColor.lightScaffoldBackground,
          boxShadow: kElevationToShadow[4],
        ),
        child:
            BlocBuilder<UpgradeBloc, UpgradeState>(builder: (context, state) {
          if (state is LoadedUpgradeState) {
            UpgradeBloc bloc = BlocProvider.of<UpgradeBloc>(context);
            Upgrade? nextUpgrade = bloc.getNextUpgrade(widget.category);

            return SafeArea(
              child: SingleChildScrollView(
                child: AnimatedContainer(
                  duration: 300.ms,
                  width: 80.w,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20))),
                        child: Column(
                          children: [
                            Text(
                              widget.category.category.name.capitalize,
                              style: GoogleFonts.robotoCondensed(
                                  fontSize: 20.sp, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Image.asset(
                                        "assets/icons/upgrades/${widget.category.category.name}/${widget.category.currentUpgrade.icon}"),
                                  ),
                                ),
                                const Spacer(),
                                Wrap(
                                  direction: Axis.vertical,
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50.w,
                                      child: Text(
                                        widget.category.currentUpgrade.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.robotoCondensed(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Wrap(
                                      direction: Axis.vertical,
                                      clipBehavior: Clip.hardEdge,
                                      alignment: WrapAlignment.center,
                                      runAlignment: WrapAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 50.w,
                                          child: Text(
                                            widget.category.currentUpgrade
                                                .description,
                                            overflow: TextOverflow.clip,
                                            style: GoogleFonts.robotoCondensed(
                                              fontSize: 15.sp,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      nextUpgrade == null
                          ? const Text("MAX")
                          : Column(
                              children: [
                                Text(
                                  "+${nextUpgrade.rate * 10}%",
                                  style: GoogleFonts.robotoCondensed(
                                    fontSize: 15,
                                    color: energyColor,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AnimatedTextKit(
                                    key: ValueKey<int>(
                                        widget.category.currentUpgrade.level),
                                    repeatForever: false,
                                    totalRepeatCount: 1,
                                    pause: const Duration(milliseconds: 50),
                                    animatedTexts: [
                                      ColorizeAnimatedText(
                                          "Level ${widget.category.currentUpgrade.level} / ${nextUpgrade.unlockOnPreviousLevel}",
                                          colors: [
                                            widget.color,
                                            widget.color.withOpacity(0.5)
                                          ],
                                          speed: 100.ms,
                                          textStyle:
                                              GoogleFonts.robotoCondensed(
                                            fontSize: 15,
                                          ))
                                    ]),
                                LinearProgressIndicator(
                                  color: widget.color,
                                  value: (widget.category.currentUpgrade.level /
                                          10) /
                                      (nextUpgrade.unlockOnPreviousLevel / 10),
                                ),
                              ],
                            ),
                      const SizedBox(
                        height: 20,
                      ),
                      nextUpgrade == null
                          ? const Text("MAX")
                          : SizedBox(
                              width: 50.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    bloc.add(
                                      LevelUpUpgradeEvent(widget.category,
                                          widget.category.currentUpgrade),
                                    );
                                  });
                                },
                                child: Text(
                                  "Upgrade for ${r'$'}${formatMoney(bloc.getUpgradePrice(widget.category.currentUpgrade))}",
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const CircularProgressIndicator();
        }),
      ),
    );
  }
}
