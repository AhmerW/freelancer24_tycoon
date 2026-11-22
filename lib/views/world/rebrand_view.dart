import 'dart:math';

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

/// "1.22" for a 22% boost; whole numbers for big ones ("12").
String _times(double m) =>
    m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(2);

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

        final recommended = engine.rebrandRecommended(state);
        final multiplier = engine.rebrandIncomeMultiplier(state);
        // Stars (and run earnings) at which rebranding is recommended.
        final target = max(Balance.rebrandRecommendMinStars, state.reputation);
        final targetEarnings = target * target * Balance.rebrandEarningsPerStar;
        final next = engine.nextStarEarnings(state);
        final prev = pending * pending * Balance.rebrandEarningsPerStar;
        final progress = recommended
            ? (state.stats.runEarnings - prev) /
                (next - prev).clamp(1, double.infinity)
            : state.stats.runEarnings / targetEarnings;

        final String advice;
        if (pending == 0) {
          advice = 'Earn ${dollar(Balance.rebrandEarningsPerStar)} this run '
              'for ${state.reputation > 0 ? 'a new' : 'your first'} star.';
        } else if (recommended) {
          advice = 'Great time to rebrand: income x${_times(multiplier)} '
              'forever!';
        } else {
          advice = 'Rebranding now only gives x${_times(multiplier)}. '
              'Wait for +$target ★ (at ${dollar(targetEarnings)} this run).';
        }

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
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: recommended
                      ? const Color(0xFFDDF7D2)
                      : const Color(0xFFEDE3FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: recommended
                          ? const Color(0xFF2B8A1C)
                          : GameTone.purple.lip.withValues(alpha: 0.4),
                      width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                        recommended
                            ? Icons.thumb_up_alt_rounded
                            : Icons.lightbulb_outline,
                        size: 18,
                        color: recommended
                            ? const Color(0xFF2B8A1C)
                            : GameTone.purple.lip),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(advice,
                          style: GameFonts.body(
                              size: 13, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GameProgressBar(
                value: progress,
                tone: recommended ? GameTone.green : GameTone.purple,
                height: 22,
                label: recommended
                    ? 'Next star at ${dollar(next)}'
                    : '+$pending/$target ★',
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (buttonContext) {
                  final button = GameButton(
                    tone: recommended
                        ? GameTone.yellow
                        : pending > 0
                            ? GameTone.blue
                            : GameTone.grey,
                    shine: recommended,
                    icon: Icons.auto_awesome,
                    label:
                        pending > 0 ? 'REBRAND  +$pending ★' : 'NO STARS YET',
                    fontSize: 18,
                    onPressed: pending > 0
                        ? () => _confirm(buttonContext, pending)
                        : null,
                  );
                  return recommended
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
                  '${_bonus(total)} income forever '
                  '(x${_times(game.engine.rebrandIncomeMultiplier(game.state))})',
                  textAlign: TextAlign.center,
                  style: GameFonts.display(size: 18, color: GameColors.ink),
                ),
              ),
              const SizedBox(height: 12),
              _Line(Icons.restart_alt, GameColors.bad,
                  'Resets money, skills, upgrades, AI, cities, staff and jobs.'),
              _Line(Icons.check_circle, GameColors.good,
                  'Keeps stars, goals, gift chests and your daily streak.'),
              if (!game.engine.rebrandRecommended(game.state))
                _Line(
                    Icons.lightbulb,
                    GameTone.purple.lip,
                    'Tip: it is early. Waiting until it doubles your stars '
                    'makes it much stronger.'),
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
