import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/world/stats_view.dart';

/// The "Goals" tab: achievements with progress and rewards to claim.
class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.achievementsUnlocked != b.achievementsUnlocked ||
          a.achievementsClaimed != b.achievementsClaimed ||
          a.stats != b.stats ||
          a.skillLevels != b.skillLevels ||
          a.locations.length != b.locations.length,
      builder: (context, state) {
        final game = context.read<GameCubit>();
        final engine = game.engine;
        final all = game.content.achievements;

        int rank(AchievementDef a) {
          if (state.isAchievementClaimed(a.id)) return 2;
          if (engine.achievementProgress(state, a).reached) return 0;
          return 1;
        }

        final sorted = [...all]..sort((a, b) {
            final r = rank(a).compareTo(rank(b));
            if (r != 0) return r;
            return engine
                .achievementProgress(state, b)
                .fraction
                .compareTo(engine.achievementProgress(state, a).fraction);
          });
        final claimed =
            all.where((a) => state.isAchievementClaimed(a.id)).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
          children: [
            SectionTitle('GOALS  $claimed/${all.length}'),
            for (final a in sorted) _AchievementCard(a, key: ValueKey(a.id)),
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementDef achievement;

  const _AchievementCard(this.achievement, {super.key});

  String _value(double v) =>
      achievement.condition.type == AchievementConditionType.lifetimeEarnings
          ? dollar(v)
          : formatMoney(v);

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final state = game.state;
    final progress = game.engine.achievementProgress(state, achievement);
    final claimed = state.isAchievementClaimed(achievement.id);
    final reached = progress.reached;
    final reward = game.engine.achievementReward(state, achievement);

    final card = GamePanel(
      color: claimed
          ? GameColors.panelShade
          : reached
              ? const Color(0xFFFFF6D8)
              : GameColors.panel,
      borderColor: reached && !claimed ? const Color(0xFFB07800) : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconBadge(
            tone: claimed
                ? GameTone.grey
                : reached
                    ? GameTone.yellow
                    : GameTone.purple,
            size: 56,
            child: SkillIcon(achievement.icon, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrokeText(achievement.title, size: 18),
                Text(achievement.description, style: GameFonts.body(size: 12)),
                const SizedBox(height: 6),
                if (!claimed)
                  GameProgressBar(
                    value: progress.fraction,
                    tone: reached ? GameTone.yellow : GameTone.purple,
                    height: 20,
                    label:
                        '${_value(progress.current.clamp(0, progress.target))} / ${_value(progress.target)}',
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (claimed)
            const Icon(Icons.check_circle, color: Color(0xFF2B8A1C), size: 36)
          else
            Builder(
              builder: (buttonContext) => GameButton(
                tone: GameTone.yellow,
                height: 56,
                width: 92,
                shine: reached,
                onPressed: reached
                    ? () {
                        final paid = game.claimAchievement(achievement.id);
                        if (paid == null) return;
                        final fx = Fx.of(buttonContext);
                        fx.coinBurst(buttonContext, coins: 14);
                        fx.floatText(buttonContext, '+${dollar(paid)}',
                            color: GameColors.gold, size: 30);
                        fx.confetti(buttonContext);
                      }
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StrokeText('CLAIM', size: 14),
                    PriceLabel(reward, size: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return reached && !claimed
        ? card
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1, end: 1.015, duration: 700.ms)
        : card;
  }
}
