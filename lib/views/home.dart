import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';

import 'package:freelancer24_tycoon/data/repositories/functions.dart';
import 'package:freelancer24_tycoon/views/alerts/alerts_view.dart';
import 'package:freelancer24_tycoon/views/locations/locations_view.dart';
import 'package:freelancer24_tycoon/views/settings/settings_dialog.dart';
import 'package:freelancer24_tycoon/views/skills/skills_view.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrades_view.dart';
import 'package:freelancer24_tycoon/views/widgets/energybar.dart';
import 'package:freelancer24_tycoon/views/widgets/fade_indexed_stack.dart';
import 'package:google_fonts/google_fonts.dart';

const moneyColor = FlexColor.greenDarkPrimaryContainer;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 1;

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int getEnergyColor(int energy) {
    int red = energy;
    switch (energy) {
      case > 80:
        red = 200;
        break;
      case > 50:
        red = 230;
        break;
      case > 20:
        255;
    }
    return red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeIndexedStack(
            index: _selectedIndex,
            duration: const Duration(milliseconds: 400),
            children: const [
              SkillsView(),
              LocationsView(),
              UpgradesView(),
            ],
          ),
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.only(left: 10, top: 15),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2F7D3)),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: moneyColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: BlocBuilder<UserBloc, UserState>(
                          builder: (context, state) {
                            if (state is LoadedUserState) {
                              return AnimatedTextKit(
                                  key: ValueKey<double>(state.balance),
                                  repeatForever: false,
                                  totalRepeatCount: 1,
                                  pause: const Duration(milliseconds: 450),
                                  animatedTexts: [
                                    ColorizeAnimatedText(
                                      "${r'$'}${formatMoney(state.balance)}",
                                      textStyle: GoogleFonts.robotoCondensed(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5),
                                      colors: [
                                        // get color from theme of context (flex colors)

                                        moneyColor.withOpacity(0.5),
                                        moneyColor,
                                        FlexColor.greenDarkPrimaryContainer,
                                      ],
                                    )
                                  ]);
                            }
                            return const Text("Loading...");
                          },
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.only(left: 10, top: 60),
              child: const EnergyBarWidget(),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 80),
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                _onNavigationTapped(2);
              },
              child: Icon(
                _selectedIndex == 2
                    ? Icons.shopping_bag
                    : Icons.shopping_bag_outlined,
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                // go to SkillsView  change index

                _onNavigationTapped(0);
              },
              child: Icon(
                _selectedIndex == 0
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 40, bottom: 40),
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              onPressed: () {
                // go to SkillsView  change index

                _onNavigationTapped(1);
              },
              child: Icon(
                _selectedIndex == 1 ? Icons.home : Icons.home_outlined,
              ),
            ),
          ),
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 115, left: 15),
            child: IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog());
              },
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          BlocBuilder<AlertBloc, AlertState>(
            builder: (context, state) {
              if (state is LoadedAlertState) {
                if (state.alerts.isEmpty) {
                  return const SizedBox.shrink();
                }
              }
              return Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(top: 15),
                  child: const AlertsView());
            },
          )
        ],
      ),
    );
  }
}
