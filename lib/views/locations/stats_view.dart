import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.stats != b.stats ||
          a.employees != b.employees ||
          a.locations.length != b.locations.length,
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final day = game.now().difference(state.startedAt).inDays + 1;
        final cities = state.locations.length;
        final staff = state.hiredCount;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Freelancing day $day',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text('${state.stats.contractsCompleted} contracts completed'),
              Text('$staff employee${staff == 1 ? '' : 's'} across '
                  '$cities cit${cities == 1 ? 'y' : 'ies'}'),
              Text('${dollar(state.stats.lifetimeEarnings)} earned in total'),
            ],
          ),
        );
      },
    );
  }
}
