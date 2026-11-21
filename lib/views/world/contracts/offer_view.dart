import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
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
      return 'Missing skills: upgrade them or pick someone who has them';
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Drop people who became busy since they were selected.
    _selected.removeWhere((id) => id == kPlayerId
        ? state.playerBusy
        : (state.employee(id)?.isBusy ?? true));
    final blocker = _blocker(game);
    final team = _selected.isEmpty ? const [kPlayerId] : _selected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: offer.golden
            ? const BorderSide(color: Color(0xFFFFB300), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RandomAvatar(offer.client,
                    width: 44, height: 44, trBackground: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(offer.client,
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (offer.golden) ...[
                            const SizedBox(width: 6),
                            const StatChip(
                              icon: Icons.star,
                              label: 'VIP',
                              color: Color(0xFFE09B00),
                              tooltip: 'VIP clients pay 3x',
                            ),
                          ],
                        ],
                      ),
                      Text('"${offer.message}"',
                          style: text.bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatChip(
                    icon: Icons.payments_outlined,
                    label: dollar(offer.pay),
                    color: Colors.green.shade800),
                StatChip(
                    icon: Icons.schedule,
                    label: formatDuration(offer.duration)),
                StatChip(
                    icon: Icons.bolt,
                    label: '${offer.energy}',
                    color: const Color(0xFF8D5A00),
                    tooltip: 'Energy used if you work on it yourself'),
                StatChip(
                    icon: Icons.group_outlined,
                    label: '${offer.requiredPeople}',
                    tooltip: 'People needed'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Needs', style: text.labelLarge),
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
            const SizedBox(height: 12),
            Text(
                'Who works on it? (${_selected.length}/${offer.requiredPeople})',
                style: text.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
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
                child: Text(blocker, style: TextStyle(color: scheme.error)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: () => game.rejectOffer(offer.id),
                  child: const Text('Decline'),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.handshake_outlined),
                  onPressed: blocker != null
                      ? null
                      : () {
                          if (game.acceptOffer(offer.id, _selected.toList())) {
                            widget.onAccepted();
                          }
                        },
                  label: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    final color =
        ok ? Colors.green.shade700 : Theme.of(context).colorScheme.error;
    return Tooltip(
      message: teamLevel == 0
          ? 'Nobody picked has ${skill.name}'
          : 'Best level in the team: $teamLevel',
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(ok ? Icons.check_circle : Icons.cancel,
            color: color, size: 18),
        side: BorderSide(color: color),
        label: Text('${skill.name} Lv $required'),
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
    return FilterChip(
      selected: selected,
      onSelected: busy ? null : (_) => onTap(),
      avatar: isPlayer
          ? const Icon(Icons.person)
          : RandomAvatar(name, width: 24, height: 24),
      label: Text(busy ? '$name (busy)' : name),
    );
  }
}
