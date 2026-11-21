import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:random_avatar/random_avatar.dart';

class ContractView extends StatelessWidget {
  final Contract contract;
  final DateTime now;

  const ContractView({super.key, required this.contract, required this.now});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final done = contract.isCompleted;

    final card = GamePanel(
      color: done ? const Color(0xFFFFF6D8) : GameColors.panel,
      borderColor: done ? const Color(0xFFB07800) : null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBFE3FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: GameColors.ink, width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: RandomAvatar(contract.client,
                    trBackground: true, width: 42, height: 42),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(contract.client, size: 19),
                    Row(
                      children: [
                        for (final id in contract.assignees)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: id == kPlayerId
                                ? const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: Color(0xFF2E8BEA),
                                    child: Icon(Icons.person,
                                        size: 15, color: Colors.white))
                                : RandomAvatar(
                                    game.state.employee(id)?.name ?? '?',
                                    width: 22,
                                    height: 22),
                          ),
                        const SizedBox(width: 4),
                        Text(done ? 'Job done!' : 'Working on it...',
                            style: GameFonts.body(size: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const CoinIcon(size: 22),
              const SizedBox(width: 4),
              Text(formatMoney(contract.netPay),
                  style: GameFonts.display(
                      size: 20, color: const Color(0xFF2B8A1C))),
            ],
          ),
          const SizedBox(height: 10),
          if (done)
            Builder(
              builder: (buttonContext) => GameButton(
                tone: GameTone.yellow,
                height: 54,
                icon: Icons.payments,
                label: 'COLLECT ${dollar(contract.netPay)}',
                shine: true,
                onPressed: () {
                  final fx = Fx.of(buttonContext);
                  // Measure before the card disappears.
                  fx.coinBurst(buttonContext, coins: 12);
                  fx.floatText(buttonContext, '+${dollar(contract.netPay)}',
                      color: GameColors.gold, size: 30);
                  game.collectContract(contract.id);
                },
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.03, duration: 600.ms),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GameProgressBar(
                    value: contract.progress(now),
                    tone: GameTone.blue,
                    height: 26,
                    label: formatDuration(contract.remaining(now)),
                  ),
                ),
                const SizedBox(width: 8),
                GameButton.small(
                  tone: GameTone.red,
                  icon: Icons.close,
                  width: 40,
                  onPressed: () => _confirmCancel(context, game),
                ),
              ],
            ),
        ],
      ),
    );
    return card;
  }

  Future<void> _confirmCancel(BuildContext context, GameCubit game) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this job?'),
        content: Text("You won't get paid and spent energy is lost.",
            style: GameFonts.body()),
        actions: [
          GameButton.small(
            tone: GameTone.blue,
            label: 'KEEP WORKING',
            onPressed: () => Navigator.pop(context, false),
          ),
          GameButton.small(
            tone: GameTone.red,
            label: 'CANCEL JOB',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (yes == true) game.cancelContract(contract.id);
  }
}
