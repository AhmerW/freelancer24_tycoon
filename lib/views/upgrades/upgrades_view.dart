import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrade_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class UpgradesView extends StatelessWidget {
  static const _colors = [
    FlexColor.orangeM3DarkPrimary,
    FlexColor.blueDarkPrimary,
    FlexColor.greenDarkPrimary,
  ];

  const UpgradesView({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = context.read<GameCubit>().content.upgradeLines;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'Upgrades',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
              ),
              for (var i = 0; i < lines.length; i++)
                UpgradeView(lines[i], color: _colors[i % _colors.length]),
            ],
          ),
        ),
      ),
    );
  }
}
