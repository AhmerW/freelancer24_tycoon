import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';

class UpgradeView extends StatelessWidget {
  final UpgradeLineDef line;
  final GameTone tone;

  const UpgradeView(this.line, {super.key, required this.tone});

  String get _effectLabel => switch (line.effect) {
        UpgradeEffect.income => 'INCOME',
        UpgradeEffect.energyRegen => 'ENERGY REFILL',
        // ignore: unreachable_switch_case
        _ => 'BONUS',
      };

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.upgrades[line.id] != b.upgrades[line.id] ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final engine = game.engine;
        final progress = state.upgrades[line.id]!;
        final item = engine.currentItem(state, line);
        final next = engine.nextItem(state, line);
        final maxLevel = engine.maxItemLevel(state, line);
        final atMax = progress.level >= maxLevel;
        final bonus = engine.upgradeBonus(state, line.effect);

        final double? cost;
        final bool Function()? action;
        final String verb;
        if (!atMax) {
          cost = engine.upgradeLevelCost(item, progress.level);
          action = () => game.upgradeItemLevel(line.id);
          verb = 'UPGRADE';
        } else if (next != null) {
          cost = next.price;
          action = () => game.buyNextItem(line.id);
          verb = 'BUY NEW';
        } else {
          cost = null;
          action = null;
          verb = 'MAXED OUT!';
        }
        final canAfford = cost != null && state.balance >= cost;

        return GamePanel(
          title: line.category.toUpperCase(),
          titleTone: tone,
          titleTrailing: StrokeText(
              '+${bonus.toStringAsFixed(0)}% $_effectLabel',
              size: 15,
              color: const Color(0xFFFFF2B0)),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white, tone.top.withValues(alpha: 0.5)],
                      ),
                      border: Border.all(color: GameColors.ink, width: 2),
                    ),
                    child: Image.asset(
                      'assets/icons/upgrades/${line.category}/${item.icon}',
                    )
                        .animate(
                            key: ValueKey(item.id),
                            onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                            begin: 2,
                            end: -3,
                            duration: 1400.ms,
                            curve: Curves.easeInOut),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StrokeText(item.name, size: 18),
                        Text(item.description, style: GameFonts.body(size: 13)),
                        const SizedBox(height: 4),
                        Text(
                          atMax
                              ? (next == null
                                  ? 'The best there is.'
                                  : 'Max level! Time for an upgrade.')
                              : '+${item.rate.toStringAsFixed(0)}% per level',
                          style: GameFonts.body(
                              size: 12, color: const Color(0xFF2B8A1C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GameProgressBar(
                value: progress.level / maxLevel,
                tone: tone,
                height: 24,
                label: 'LEVEL ${progress.level}/$maxLevel',
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (buttonContext) => GameButton(
                  tone:
                      next != null && atMax ? GameTone.yellow : GameTone.green,
                  height: 54,
                  shine: canAfford,
                  onPressed: canAfford
                      ? () {
                          if (!action!()) return;
                          final fx = Fx.of(buttonContext);
                          if (atMax) {
                            fx.floatText(buttonContext,
                                'NEW ${line.category.toUpperCase()}!',
                                color: GameColors.gold);
                            fx.confetti(buttonContext);
                          } else {
                            fx.floatText(buttonContext,
                                '+${item.rate.toStringAsFixed(0)}%',
                                color: const Color(0xFF9BF08A));
                          }
                        }
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: StrokeText(
                            next != null && atMax
                                ? '$verb: ${next.name}'
                                : verb,
                            size: 16,
                            maxLines: 1),
                      ),
                      if (cost != null) ...[
                        const SizedBox(width: 8),
                        PriceLabel(cost, size: 16),
                      ],
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
