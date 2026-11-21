import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

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

        Widget stat(IconData icon, GameTone tone, String value, String label) =>
            Expanded(
              child: Column(
                children: [
                  IconBadge(
                    tone: tone,
                    size: 40,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(value,
                      style:
                          GameFonts.display(size: 18, color: GameColors.ink)),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: GameFonts.body(size: 11)),
                ],
              ),
            );

        return GamePanel(
          title: 'Freelancing day $day',
          titleTone: GameTone.purple,
          titleTrailing: const Icon(Icons.calendar_month, color: Colors.white),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(Icons.task_alt, GameTone.green,
                  '${state.stats.contractsCompleted}', 'contracts'),
              stat(Icons.groups, GameTone.blue, '${state.hiredCount}',
                  'employees'),
              stat(Icons.location_city, GameTone.red,
                  '${state.locations.length}', 'cities'),
              stat(Icons.payments, GameTone.yellow,
                  dollar(state.stats.lifetimeEarnings), 'earned'),
            ],
          ),
        );
      },
    );
  }
}

/// White outlined section title on the blue background.
class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
        child: StrokeText(text, size: 24),
      );
}
