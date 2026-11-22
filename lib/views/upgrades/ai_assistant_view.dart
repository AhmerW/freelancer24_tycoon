import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';

/// The AI assistant: hire it once, then level it up. Shown at the top of the
/// Upgrades tab and in every city's Team tab.
class AiAssistantCard extends StatelessWidget {
  const AiAssistantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.aiLevel != b.aiLevel ||
          a.contracts != b.contracts ||
          a.skillLevels != b.skillLevels ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final engine = game.engine;
        final hired = engine.hasAi(state);
        final cost = engine.aiUpgradeCost(state);
        final canAfford = cost != null && state.balance >= cost;
        final slots = engine.aiTaskSlots(state);
        final nextSlot = engine.aiNextSlotLevel(state);

        Widget fact(IconData icon, String text) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: GameTone.purple.lip),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(text,
                        style:
                            GameFonts.body(size: 13, weight: FontWeight.w700)),
                  ),
                ],
              ),
            );

        final robot = IconBadge(
          tone: hired ? GameTone.purple : GameTone.grey,
          size: 62,
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 36),
        );

        return GamePanel(
          title: 'AI ASSISTANT',
          titleTone: GameTone.purple,
          titleTrailing: hired
              ? StrokeText('LV ${state.aiLevel}', size: 18)
              : const Icon(Icons.lock, color: Colors.white),
          color: const Color(0xFFF6EEFF),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  hired
                      ? robot
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                              begin: 0,
                              end: -4,
                              duration: 900.ms,
                              curve: Curves.easeInOut)
                      : robot,
                  const SizedBox(width: 12),
                  Expanded(
                    child: hired
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fact(Icons.psychology,
                                  'Knows ${(engine.aiSkillShare(state) * 100).round()}% of your skill levels'),
                              fact(
                                  Icons.task_alt,
                                  'Working on ${engine.aiTasks(state)}/$slots '
                                  'task${slots == 1 ? '' : 's'}'),
                              if (nextSlot != null)
                                fact(Icons.add_task,
                                    'Task #${slots + 1} at level $nextSlot'),
                              fact(Icons.memory,
                                  'Keeps ${Balance.aiCut}% of pay for computing'),
                            ],
                          )
                        : Text(
                            'A partner for every city. Add it to any offer '
                            'or project: it needs no energy and no desk, '
                            'and knows part of every skill you learn.',
                            style: GameFonts.body(
                                size: 13, weight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (buttonContext) => GameButton(
                  tone: cost == null
                      ? GameTone.grey
                      : hired
                          ? GameTone.green
                          : GameTone.purple,
                  height: 50,
                  shine: canAfford,
                  onPressed: canAfford
                      ? () {
                          final wasHired = hired;
                          if (!game.upgradeAi()) return;
                          final fx = Fx.of(buttonContext);
                          if (!wasHired) {
                            fx.confetti(buttonContext);
                          } else {
                            final gotSlot = Balance.aiTaskLevels
                                .contains(game.state.aiLevel);
                            fx.floatText(
                                buttonContext,
                                gotSlot
                                    ? '+1 TASK!'
                                    : 'LV ${game.state.aiLevel}',
                                sound: Sound.levelup,
                                color: const Color(0xFFE2C2FF));
                          }
                        }
                      : null,
                  child: cost == null
                      ? StrokeText('MAX LEVEL', size: 16)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StrokeText(hired ? 'UPGRADE' : 'HIRE AI', size: 16),
                            const SizedBox(width: 8),
                            PriceLabel(cost, size: 16),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
