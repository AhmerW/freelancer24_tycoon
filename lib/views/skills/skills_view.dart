import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';

class SkillsView extends StatelessWidget {
  /// How many locked skills to preview after the next one.
  static const int lockedPreview = 2;

  const SkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.skillLevels != b.skillLevels ||
          a.upgrades != b.upgrades ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final engine = game.engine;
        final next = engine.nextLockedSkill(state);
        final multiplier = engine.incomePerSecond(state) /
            (engine.baseIncomePerSecond(state).clamp(1e-9, double.infinity));
        final cards = <Widget>[];
        var teasers = 0;
        for (final SkillDef skill in game.content.skills) {
          final unlocked = state.isSkillUnlocked(skill.id);
          final status = unlocked
              ? SkillStatus.unlocked
              : skill.id == next?.id
                  ? SkillStatus.next
                  : SkillStatus.locked;
          if (status == SkillStatus.locked && teasers++ >= lockedPreview) break;
          final level = state.skillLevel(skill.id);
          final cost =
              unlocked ? engine.skillUpgradeCost(skill, level) : skill.price;
          cards.add(SkillCard(
            key: ValueKey(skill.id),
            skill: skill,
            level: level,
            status: status,
            blocker: unlocked ? null : engine.skillUnlockBlocker(state, skill),
            cost: cost,
            canAfford: state.balance >= cost,
            incomeGain: engine.skillIncome(skill, 1) * multiplier,
            onPressed: unlocked
                ? () => game.upgradeSkill(skill.id)
                : () => game.unlockSkill(skill.id),
          ));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Skills ${state.skillLevels.length}/${game.content.skills.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...cards,
          ],
        );
      },
    );
  }
}
