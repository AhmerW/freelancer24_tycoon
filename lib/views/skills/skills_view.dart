import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
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
        final text = Theme.of(context).textTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Skills ${state.skillLevels.length}/${content.skills.length}',
                style: text.titleLarge,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final t in content.tracks)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TrackChip(
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

class _TrackChip extends StatelessWidget {
  final TrackDef track;
  final bool selected;
  final bool open;
  final int learned;
  final bool hasAffordableSkill;
  final VoidCallback onTap;

  const _TrackChip({
    required this.track,
    required this.selected,
    required this.open,
    required this.learned,
    required this.hasAffordableSkill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(track.color);
    final fg = selected ? Colors.white : (open ? color : Colors.grey);
    return Badge(
      isLabelVisible: hasAffordableSkill && !selected,
      smallSize: 10,
      backgroundColor: Colors.green.shade600,
      child: Material(
        color: selected ? color : color.withValues(alpha: open ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                open
                    ? SkillIcon(track.icon, size: 22, color: fg)
                    : Icon(Icons.lock_outline, size: 18, color: fg),
                const SizedBox(width: 6),
                Text(
                  '${track.name}  $learned/7',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
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
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            open
                ? track.description
                : '${track.description}\n${engine.skillUnlockBlocker(state, game.content.skillsInTrack(track.id).first)}.',
            style: text.bodyMedium?.copyWith(color: open ? null : color),
          ),
        ),
        for (final skill in game.content.skillsInTrack(track.id))
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
              incomeGain: engine.skillIncome(skill, 1) * multiplier,
              onPressed: unlocked
                  ? () => game.upgradeSkill(skill.id)
                  : () => game.unlockSkill(skill.id),
            );
          }),
      ],
    );
  }
}
