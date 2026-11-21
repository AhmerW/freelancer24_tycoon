import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/widgets/responsive.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillsView extends StatelessWidget {
  /// How many locked skills to preview after the unlocked ones.
  static const int lockedPreview = 5;

  const SkillsView({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.skillLevels != b.skillLevels ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final engine = game.engine;
        final next = engine.nextLockedSkill(state);
        final entries = <Widget>[];
        var lockedShown = 0;
        for (final SkillDef skill in game.content.skills) {
          final unlocked = state.isSkillUnlocked(skill.id);
          if (!unlocked && lockedShown++ >= lockedPreview) break;
          final level = state.skillLevel(skill.id);
          final cost =
              unlocked ? engine.skillUpgradeCost(skill, level) : skill.price;
          entries.add(SizedBox(
            height: 300,
            width: 300,
            child: SkillWidget(
              key: ValueKey(skill.id),
              skill: skill,
              level: level,
              status: unlocked
                  ? SkillStatus.unlocked
                  : skill.id == next?.id
                      ? SkillStatus.next
                      : SkillStatus.locked,
              blocker:
                  unlocked ? null : engine.skillUnlockBlocker(state, skill),
              cost: cost,
              canAfford: state.balance >= cost,
              onPressed: unlocked
                  ? () => game.upgradeSkill(skill.id)
                  : () => game.unlockSkill(skill.id),
            ),
          ));
        }

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Skills (${state.skillLevels.length}/${game.content.skills.length})',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return GridView.count(
                        crossAxisCount:
                            responsiveCrossAxisCount(constraints.maxWidth),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: entries,
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 160),
                      children: entries,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
