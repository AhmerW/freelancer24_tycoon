import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:random_avatar/random_avatar.dart';

class OfferView extends StatefulWidget {
  final Contract offer;
  final LocationDef location;
  final VoidCallback onAccepted;

  const OfferView({
    super.key,
    required this.offer,
    required this.location,
    required this.onAccepted,
  });

  @override
  State<OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends State<OfferView> {
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    // Most offers early on are one-person jobs for the player: pre-select them.
    if (!context.read<GameCubit>().state.playerBusy) _selected.add(kPlayerId);
  }

  void _toggle(int id, int required) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < required) {
        _selected.add(id);
      } else if (required == 1) {
        _selected
          ..clear()
          ..add(id);
      }
    });
  }

  /// Why the offer can't be accepted with the current selection, or null.
  String? _blocker(GameCubit game) {
    final offer = widget.offer;
    final state = game.state;
    if (_selected.length != offer.requiredPeople) {
      return 'Pick ${offer.requiredPeople} '
          '${offer.requiredPeople == 1 ? 'person' : 'people'} below';
    }
    if (!game.engine.teamCovers(state, offer, _selected)) {
      return 'Missing skills: level up or pick someone who has them';
    }
    if (_selected.contains(kPlayerId) && state.energy < offer.energy) {
      return 'Not enough energy: wait a bit or send an employee';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final state = game.state;
    final offer = widget.offer;

    // Drop people who became busy since they were selected.
    _selected.removeWhere((id) => id == kPlayerId
        ? state.playerBusy
        : (state.employee(id)?.isBusy ?? true));
    final blocker = _blocker(game);
    final team = _selected.isEmpty ? const [kPlayerId] : _selected;

    final card = GamePanel(
      borderColor: offer.golden ? const Color(0xFFB07800) : null,
      color: offer.golden ? const Color(0xFFFFF6D8) : GameColors.panel,
      title: offer.golden ? 'VIP CLIENT · PAYS 3X' : null,
      titleTone: GameTone.yellow,
      titleTrailing: offer.golden
          ? const Icon(Icons.star, color: Colors.white)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3.seconds)
          : null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFBFE3FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: GameColors.ink, width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: RandomAvatar(offer.client,
                    width: 46, height: 46, trBackground: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(offer.client, size: 20),
                    Text('"${offer.message}"',
                        style:
                            GameFonts.body(size: 13, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatChip(
                  icon: Icons.attach_money,
                  label: dollar(offer.pay),
                  color: const Color(0xFF2B8A1C)),
              StatChip(
                  icon: Icons.schedule,
                  label: formatDuration(offer.duration),
                  color: const Color(0xFF2E8BEA)),
              StatChip(
                  icon: Icons.bolt,
                  label: '${offer.energy}',
                  color: GameColors.energyDark,
                  tooltip: 'Energy used if you work on it yourself'),
              StatChip(
                  icon: Icons.group,
                  label: '${offer.requiredPeople}',
                  color: const Color(0xFFE65100),
                  tooltip: 'People needed'),
            ],
          ),
          const SizedBox(height: 10),
          Text('NEEDS',
              style: GameFonts.display(size: 14, color: GameColors.ink)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final req in offer.requirements)
                _RequirementChip(
                  skill: game.content.skill(req.skillId),
                  required: req.level,
                  teamLevel: game.engine.bestLevel(state, team, req.skillId),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('WHO WORKS ON IT? (${_selected.length}/${offer.requiredPeople})',
              style: GameFonts.display(size: 14, color: GameColors.ink)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PersonChip(
                name: 'You',
                isPlayer: true,
                busy: state.playerBusy,
                selected: _selected.contains(kPlayerId),
                onTap: () => _toggle(kPlayerId, offer.requiredPeople),
              ),
              for (final e in state.hiredAt(widget.location.id))
                _PersonChip(
                  name: e.name,
                  busy: e.isBusy,
                  selected: _selected.contains(e.id),
                  onTap: () => _toggle(e.id, offer.requiredPeople),
                ),
            ],
          ),
          if (blocker != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(blocker,
                  style: GameFonts.body(size: 13, color: GameColors.bad)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              GameButton.small(
                tone: GameTone.red,
                icon: Icons.close,
                label: 'NO',
                onPressed: () => game.rejectOffer(offer.id),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  tone: GameTone.green,
                  icon: Icons.handshake,
                  label: 'ACCEPT',
                  shine: blocker == null,
                  onPressed: blocker != null
                      ? null
                      : () {
                          if (game.acceptOffer(offer.id, _selected.toList())) {
                            Sfx.instance.play(Sound.whoosh);
                            widget.onAccepted();
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return card
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOutBack);
  }
}

class _RequirementChip extends StatelessWidget {
  final SkillDef skill;
  final int required;
  final int teamLevel;

  const _RequirementChip({
    required this.skill,
    required this.required,
    required this.teamLevel,
  });

  @override
  Widget build(BuildContext context) {
    final ok = teamLevel >= required;
    return Tooltip(
      message: teamLevel == 0
          ? 'Nobody picked has ${skill.name}'
          : 'Best level in the team: $teamLevel',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFDDF7D2) : const Color(0xFFFFE0DC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: ok ? const Color(0xFF2B8A1C) : GameColors.bad, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ok ? Icons.check_circle : Icons.cancel,
                size: 20, color: ok ? const Color(0xFF2B8A1C) : GameColors.bad),
            const SizedBox(width: 4),
            Text('${skill.name} Lv $required',
                style: GameFonts.body(size: 13, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  final String name;
  final bool isPlayer;
  final bool busy;
  final bool selected;
  final VoidCallback onTap;

  const _PersonChip({
    required this.name,
    this.isPlayer = false,
    required this.busy,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = busy
        ? GameTone.grey
        : selected
            ? GameTone.blue
            : const GameTone(
                Colors.white, Color(0xFFE3ECFA), Color(0xFFB8C7E3));
    return Bouncy(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tone.top, tone.bottom],
          ),
          border: Border.all(color: GameColors.ink, width: 2),
          boxShadow: [BoxShadow(color: tone.lip, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: isPlayer
                  ? const Icon(Icons.person, color: GameColors.ink, size: 20)
                  : RandomAvatar(name, width: 26, height: 26),
            ),
            const SizedBox(width: 6),
            selected
                ? StrokeText(name, size: 15)
                : Text(busy ? '$name (busy)' : name,
                    style: GameFonts.display(size: 15, color: GameColors.ink)),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
