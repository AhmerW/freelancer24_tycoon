import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';

/// The "Skills" tab: career tracks and their skill ladders.
class SkillsView extends StatefulWidget {
  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  String? _trackId;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final content = game.content;
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.skillLevels != b.skillLevels ||
          a.upgrades != b.upgrades ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final engine = game.engine;
        final track = content.track(_trackId ?? content.tracks.first.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: StrokeText(
                'SKILLS  ${state.skillLevels.length}/${content.skills.length}',
                size: 26,
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                children: [
                  for (final t in content.tracks)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TrackTab(
                        track: t,
                        selected: t.id == track.id,
                        open: engine.isTrackOpen(state, t),
                        learned: content
                            .skillsInTrack(t.id)
                            .where((s) => state.isSkillUnlocked(s.id))
                            .length,
                        hasAffordableSkill:
                            _affordableNext(engine, state, t) != null,
                        onTap: () => setState(() => _trackId = t.id),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _TrackLadder(track: track, state: state)),
          ],
        );
      },
    );
  }

  /// The track's next skill if it can be learned and afforded right now.
  static SkillDef? _affordableNext(
      GameEngine engine, GameState state, TrackDef track) {
    if (!engine.isTrackOpen(state, track)) return null;
    final next = engine.nextSkillInTrack(state, track);
    if (next == null ||
        engine.skillUnlockBlocker(state, next) != null ||
        state.balance < next.price) {
      return null;
    }
    return next;
  }
}

class _TrackTab extends StatelessWidget {
  final TrackDef track;
  final bool selected;
  final bool open;
  final int learned;
  final bool hasAffordableSkill;
  final VoidCallback onTap;

  const _TrackTab({
    required this.track,
    required this.selected,
    required this.open,
    required this.learned,
    required this.hasAffordableSkill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = open ? GameTone.from(Color(track.color)) : GameTone.grey;
    return Bouncy(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(top: selected ? 0 : 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? [tone.top, tone.bottom]
                    : [
                        tone.bottom.withValues(alpha: 0.55),
                        tone.lip.withValues(alpha: 0.7),
                      ],
              ),
              border: Border.all(
                  color: selected ? Colors.white : GameColors.ink,
                  width: selected ? 3 : 2),
              boxShadow: [
                BoxShadow(color: tone.lip, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                open
                    ? SkillIcon(track.icon, size: 24)
                    : const Icon(Icons.lock, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(track.name, size: 14),
                    StrokeText('$learned/7',
                        size: 11, color: const Color(0xFFFFE9A8)),
                  ],
                ),
              ],
            ),
          ),
          if (hasAffordableSkill && !selected)
            Positioned(
              right: -4,
              top: -6,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GameColors.bad,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: StrokeText('!', size: 13),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.85, end: 1.1, duration: 600.ms),
            ),
        ],
      ),
    );
  }
}

class _TrackLadder extends StatelessWidget {
  final TrackDef track;
  final GameState state;

  const _TrackLadder({required this.track, required this.state});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final engine = game.engine;
    final color = Color(track.color);
    final open = engine.isTrackOpen(state, track);
    final next = open ? engine.nextSkillInTrack(state, track) : null;
    // Income gained per level, including upgrade bonuses.
    final base = engine.baseIncomePerSecond(state);
    final multiplier = base > 0 ? engine.incomePerSecond(state) / base : 1.0;
    final skills = game.content.skillsInTrack(track.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            open
                ? track.description
                : '${track.description}\n${engine.skillUnlockBlocker(state, skills.first)}.',
            style: GameFonts.body(color: Colors.white, size: 14),
          ),
        ),
        for (final skill in skills)
          Builder(builder: (context) {
            final unlocked = state.isSkillUnlocked(skill.id);
            final level = state.skillLevel(skill.id);
            final cost =
                unlocked ? engine.skillUpgradeCost(skill, level) : skill.price;
            return SkillCard(
              key: ValueKey(skill.id),
              skill: skill,
              level: level,
              accent: color,
              status: unlocked
                  ? SkillStatus.unlocked
                  : skill.id == next?.id
                      ? SkillStatus.next
                      : SkillStatus.locked,
              blocker:
                  unlocked ? null : engine.skillUnlockBlocker(state, skill),
              cost: cost,
              canAfford: state.balance >= cost,
              incomeGain: (unlocked
                      ? engine.skillIncome(skill, level + 1) -
                          engine.skillIncome(skill, level)
                      : engine.skillIncome(skill, 1)) *
                  multiplier,
              milestoneMultiplier: engine.milestoneMultiplier(level),
              previousMilestone: Balance.skillMilestones
                  .lastWhere((m) => m <= level, orElse: () => 0),
              nextMilestone: engine.nextMilestone(level),
              onPressed: unlocked
                  ? () => game.upgradeSkill(skill.id)
                  : () => game.unlockSkill(skill.id),
            );
          }),
      ],
    );
  }
}
