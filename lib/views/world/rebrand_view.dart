import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

const _starColor = Color(0xFFFFD23F);

String _bonus(int stars) =>
    '+${(stars * Balance.reputationBonusPerStar * 100).round()}%';

/// Rebrand (prestige): start over with reputation stars that boost income.
/// Appears once the player is a tenth of the way to their first star.
class RebrandCard extends StatelessWidget {
  const RebrandCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.reputation != b.reputation ||
          a.stats.runEarnings.floor() != b.stats.runEarnings.floor(),
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final engine = game.engine;
        final pending = engine.pendingStars(state);
        final visible = state.reputation > 0 ||
            state.stats.runEarnings >= Balance.rebrandEarningsPerStar * 0.1;
        if (!visible) return const SizedBox.shrink();

        final next = engine.nextStarEarnings(state);
        final prev = pending * pending * Balance.rebrandEarningsPerStar;
        final progress = (state.stats.runEarnings - prev) /
            (next - prev).clamp(1, double.infinity);

        return GamePanel(
          title: 'REBRAND',
          titleTone: GameTone.purple,
          titleTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _starColor, size: 26),
              StrokeText('${state.reputation}', size: 20),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.reputation > 0
                    ? 'Your reputation gives ${_bonus(state.reputation)} income.'
                    : 'Start over under a new name. Reputation stars boost '
                        'all income forever.',
                style: GameFonts.body(size: 13),
              ),
              const SizedBox(height: 8),
              GameProgressBar(
                value: progress,
                tone: GameTone.purple,
                height: 22,
                label: 'Next star at ${dollar(next)}',
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (buttonContext) {
                  final button = GameButton(
                    tone: pending > 0 ? GameTone.yellow : GameTone.grey,
                    shine: pending > 0,
                    icon: Icons.auto_awesome,
                    label: pending > 0
                        ? 'REBRAND  +$pending ★'
                        : 'EARN ${dollar(Balance.rebrandEarningsPerStar)} THIS RUN',
                    fontSize: pending > 0 ? 18 : 14,
                    onPressed: pending > 0
                        ? () => _confirm(buttonContext, pending)
                        : null,
                  );
                  return pending > 0
                      ? button
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.98, end: 1.02, duration: 700.ms)
                      : button;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context, int pending) async {
    final game = context.read<GameCubit>();
    final fx = Fx.of(context);
    final total = game.state.reputation + pending;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GamePanel(
          title: 'REBRAND?',
          titleTone: GameTone.purple,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pending.clamp(1, 5); i++)
                    const Icon(Icons.star_rounded, color: _starColor, size: 44)
                        .animate(delay: (i * 120).ms)
                        .scaleXY(
                            begin: 0,
                            end: 1,
                            curve: Curves.elasticOut,
                            duration: 700.ms),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '+$pending star${pending == 1 ? '' : 's'}: '
                  '${_bonus(total)} income forever',
                  textAlign: TextAlign.center,
                  style: GameFonts.display(size: 18, color: GameColors.ink),
                ),
              ),
              const SizedBox(height: 12),
              _Line(Icons.restart_alt, GameColors.bad,
                  'Resets money, skills, upgrades, cities, staff and jobs.'),
              _Line(Icons.check_circle, GameColors.good,
                  'Keeps stars, goals, gift chests and your daily streak.'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      tone: GameTone.blue,
                      label: 'NOT YET',
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GameButton(
                      tone: GameTone.yellow,
                      shine: true,
                      label: 'REBRAND!',
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    final gained = game.rebrand();
    if (gained == null) return;
    fx.confetti();
    if (context.mounted) {
      fx.floatText(context, '+$gained ★', color: _starColor, size: 40);
    }
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Line(this.icon, this.color, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: GameFonts.body(size: 13))),
          ],
        ),
      );
}
