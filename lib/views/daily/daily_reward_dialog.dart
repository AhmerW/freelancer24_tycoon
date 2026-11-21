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

Future<void> showDailyReward(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const DailyRewardDialog(),
    );

/// A 7-day reward calendar. Come back every day to keep the streak going.
class DailyRewardDialog extends StatelessWidget {
  const DailyRewardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.dailyStreak != b.dailyStreak ||
          a.lastDailyClaim != b.lastDailyClaim,
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final status = game.dailyReward;
        // Days of the current cycle already claimed.
        final claimedInCycle = status.available ? status.day - 1 : status.day;

        Widget tile(int day) {
          final claimed = day <= claimedInCycle;
          final today = status.available && day == status.day;
          final big = day == 7;
          final energy = game.engine.dailyRewardRefillsEnergy(day);
          final cash = game.engine.dailyRewardCash(state, day);
          final tone = claimed
              ? GameTone.grey
              : today
                  ? GameTone.yellow
                  : big
                      ? GameTone.purple
                      : GameTone.blue;
          Widget box = Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tone.top, tone.bottom],
              ),
              border: Border.all(
                  color: today ? Colors.white : GameColors.ink,
                  width: today ? 3 : 2),
              boxShadow: [
                BoxShadow(color: tone.lip, offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StrokeText('DAY $day', size: 13),
                const SizedBox(height: 4),
                if (claimed)
                  const Icon(Icons.check_circle, color: Colors.white, size: 30)
                else
                  Icon(
                    big ? Icons.card_giftcard : Icons.payments,
                    color: Colors.white,
                    size: big ? 36 : 28,
                    shadows: const [
                      Shadow(color: GameColors.ink, offset: Offset(0, 2))
                    ],
                  ),
                const SizedBox(height: 4),
                StrokeText(formatMoney(cash), size: 13),
                if (energy)
                  const Icon(Icons.bolt, color: Color(0xFFFFF2B0), size: 16),
              ],
            ),
          );
          if (today) {
            box = box
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.95, end: 1.06, duration: 600.ms);
          }
          return box;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GamePanel(
            title: 'DAILY REWARD',
            titleTone: GameTone.yellow,
            titleTrailing: GameButton.small(
              tone: GameTone.red,
              icon: Icons.close,
              width: 36,
              onPressed: () => Navigator.of(context).pop(),
            ),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFF7A00), size: 26),
                    const SizedBox(width: 4),
                    Text(
                      'Streak: ${status.available ? status.streak - 1 : status.streak} '
                      'day${(status.available ? status.streak - 1 : status.streak) == 1 ? '' : 's'}',
                      style: GameFonts.display(size: 18, color: GameColors.ink),
                    ),
                  ],
                ),
                Text('Come back every day. Day 7 is the big one!',
                    style: GameFonts.body(size: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var d = 1; d <= 4; d++) ...[
                      if (d > 1) const SizedBox(width: 6),
                      Expanded(child: tile(d)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var d = 5; d <= 7; d++) ...[
                      if (d > 5) const SizedBox(width: 6),
                      Expanded(child: tile(d)),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (status.available)
                  Builder(
                    builder: (buttonContext) => GameButton(
                      tone: GameTone.green,
                      height: 56,
                      shine: true,
                      icon: Icons.redeem,
                      label: 'CLAIM DAY ${status.day}',
                      onPressed: () {
                        final paid = game.claimDailyReward();
                        if (paid == null) return;
                        final fx = Fx.of(buttonContext);
                        fx.coinBurst(buttonContext, coins: 14);
                        fx.floatText(buttonContext, '+${dollar(paid)}',
                            color: GameColors.gold, size: 30);
                        fx.confetti(buttonContext);
                      },
                    ),
                  )
                else
                  StrokeText(
                    'Next reward in ${formatDuration(_untilTomorrow(game.now()))}',
                    size: 16,
                    color: const Color(0xFFFFE9A8),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Duration _untilTomorrow(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).difference(now);
}

/// Gift button for the HUD; bounces when a reward is waiting.
class DailyRewardButton extends StatelessWidget {
  const DailyRewardButton({super.key});

  @override
  Widget build(BuildContext context) {
    final available = context.select((GameCubit c) => c.dailyReward.available);
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        GameButton(
          tone: available ? GameTone.yellow : GameTone.blue,
          height: 40,
          width: 40,
          icon: Icons.card_giftcard,
          fontSize: 16,
          onPressed: () => showDailyReward(context),
        ),
        if (available)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: GameColors.bad,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
    return available
        ? button
            .animate(onPlay: (c) => c.repeat())
            .shake(hz: 4, rotation: 0.08, duration: 600.ms)
            .then(delay: 1800.ms)
        : button;
  }
}
