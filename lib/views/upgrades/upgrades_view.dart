import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/upgrades/upgrade_bloc.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrade_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class UpgradesView extends StatefulWidget {
  const UpgradesView({super.key});

  @override
  State<UpgradesView> createState() => _UpgradesViewState();
}

class _UpgradesViewState extends State<UpgradesView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpgradeBloc, UpgradeState>(builder: (context, state) {
      if (state is LoadedUpgradeState) {
        return SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  height: 100,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      Text(
                        "Oppgraderinger",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                UpgradeView(
                  state.coffeeCategory,
                  color: FlexColor.orangeM3DarkPrimary,
                ),
                UpgradeView(state.chairCategory,
                    color: FlexColor.blueDarkPrimary),
              ],
            ),
          ),
        );
      }
      return const Center(
        child: Text("Upgrades not loaded"),
      );
    });
  }
}
