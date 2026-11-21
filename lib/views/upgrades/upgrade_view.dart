import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

class UpgradeView extends StatelessWidget {
  final UpgradeLineDef line;
  final Color color;

  const UpgradeView(this.line, {super.key, required this.color});

  String get _title =>
      line.category[0].toUpperCase() + line.category.substring(1);

  String get _effectLabel => switch (line.effect) {
        UpgradeEffect.income => 'income',
        UpgradeEffect.energyRegen => 'energy refill speed',
      };

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final text = Theme.of(context).textTheme;
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

        final String label;
        final double? cost;
        final VoidCallback? action;
        if (!atMax) {
          cost = engine.upgradeLevelCost(item, progress.level);
          label = 'Upgrade · ${dollar(cost)}';
          action = () => game.upgradeItemLevel(line.id);
        } else if (next != null) {
          cost = next.price;
          label = 'Buy ${next.name} · ${dollar(cost)}';
          action = () => game.buyNextItem(line.id);
        } else {
          cost = null;
          label = 'Maxed out!';
          action = null;
        }
        final canAfford = cost != null && state.balance >= cost;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: color.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/upgrades/${line.category}/${item.icon}',
                      width: 64,
                      height: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title.toUpperCase(),
                              style: text.labelMedium?.copyWith(
                                  color: color, fontWeight: FontWeight.bold)),
                          Text(item.name,
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(item.description,
                              style: text.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '+${bonus.toStringAsFixed(0)}% $_effectLabel',
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('Level ${progress.level}/$maxLevel',
                            style: text.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.level / maxLevel,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atMax
                          ? (next == null
                              ? 'The best there is.'
                              : 'Max level. Time for something better!')
                          : '+${item.rate.toStringAsFixed(0)}% per level'
                              '${next == null ? '' : ' · next item at level $maxLevel'}',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: color),
                      onPressed: canAfford ? action : null,
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
