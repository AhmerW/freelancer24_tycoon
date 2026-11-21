import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrade_view.dart';
import 'package:freelancer24_tycoon/views/world/stats_view.dart';

class UpgradesView extends StatelessWidget {
  static const _tones = [GameTone.red, GameTone.blue, GameTone.purple];

  const UpgradesView({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = context.read<GameCubit>().content.upgradeLines;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
      children: [
        const SectionTitle('OFFICE UPGRADES'),
        for (var i = 0; i < lines.length; i++)
          UpgradeView(lines[i], tone: _tones[i % _tones.length]),
      ],
    );
  }
}
