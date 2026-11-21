import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrade_view.dart';

class UpgradesView extends StatelessWidget {
  static const _colors = [
    Color(0xFFE65100),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
  ];

  const UpgradesView({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = context.read<GameCubit>().content.upgradeLines;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Office upgrades',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        for (var i = 0; i < lines.length; i++)
          UpgradeView(lines[i], color: _colors[i % _colors.length]),
      ],
    );
  }
}
