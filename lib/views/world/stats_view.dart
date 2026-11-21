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
          a.stats.contractsCompleted != b.stats.contractsCompleted ||
          a.stats.lifetimeEarnings.floor() !=
              b.stats.lifetimeEarnings.floor() ||
          a.hiredCount != b.hiredCount ||
          a.locations.length != b.locations.length,
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final day = game.now().difference(state.startedAt).inDays + 1;
        final text = Theme.of(context).textTheme;

        Widget stat(String value, String label) => Expanded(
              child: Column(
                children: [
                  Text(value,
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      textAlign: TextAlign.center, style: text.labelMedium),
                ],
              ),
            );

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Text('Freelancing day $day', style: text.titleMedium),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat(
                        '${state.stats.contractsCompleted}', 'contracts\ndone'),
                    stat('${state.hiredCount}', 'employees'),
                    stat('${state.locations.length}', 'cities'),
                    stat(dollar(state.stats.lifetimeEarnings),
                        'earned\nin total'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
