import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const Color energyColor = Colors.black;

class EnergyBarWidget extends StatefulWidget {
  const EnergyBarWidget({super.key});

  @override
  State<EnergyBarWidget> createState() => _EnergyBarWidgetState();
}

class _EnergyBarWidgetState extends State<EnergyBarWidget> {
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: IntrinsicWidth(
        child: BlocBuilder<UserBloc, UserState>(builder: (context, state) {
          if (state is LoadedUserState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 240, 218, 109)),
                  onPressed: () {},
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: energyColor,
                      ),
                      const Spacer(),
                      AnimatedTextKit(
                          key: ValueKey<double>(state.balance),
                          repeatForever: false,
                          totalRepeatCount: 1,
                          pause: const Duration(milliseconds: 450),
                          animatedTexts: [
                            ColorizeAnimatedText(
                              "${state.energy}/100",
                              textStyle: GoogleFonts.robotoCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              colors: [
                                // get color from theme of context (flex colors)

                                energyColor.withOpacity(0.8),
                                energyColor,
                                Colors.orange,
                              ],
                            )
                          ]),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}
