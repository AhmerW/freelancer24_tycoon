import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Most early offers are one-person jobs for the player: pre-select them.
    final state = context.read<GameCubit>().state;
    if (!state.playerBusy) _selected.add(kPlayerId);
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
          '${offer.requiredPeople == 1 ? 'person' : 'people'}';
    }
    if (!game.engine.teamCovers(state, offer, _selected)) {
      return 'The team is missing required skills';
    }
    if (_selected.contains(kPlayerId) && state.energy < offer.energy) {
      return 'Not enough energy';
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

    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(width: 2, color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.6),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${offer.golden ? 'GOLDEN ' : ''}Offer by ${offer.client}',
            style: GoogleFonts.robotoCondensed(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: offer.golden ? Colors.orange : null,
            ),
          ),
          AnimatedTextKit(
            repeatForever: false,
            totalRepeatCount: 1,
            animatedTexts: [
              TyperAnimatedText(
                offer.message,
                speed: const Duration(milliseconds: 20),
                textStyle: GoogleFonts.robotoCondensed(fontSize: 16.sp),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RandomAvatar(offer.client,
                  width: 64, height: 64, trBackground: true),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    OfferLabel(
                        icon: Icons.schedule_outlined,
                        color: Colors.black,
                        text: formatDuration(offer.duration)),
                    OfferLabel(
                        icon: Icons.payment_outlined,
                        color: Colors.green,
                        text: dollar(offer.pay)),
                    OfferLabel(
                        icon: Icons.bolt_outlined,
                        color: Colors.orange,
                        text: '${offer.energy}'),
                    OfferLabel(
                        icon: Icons.people_outline,
                        color: Colors.black,
                        text: '${offer.requiredPeople}'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          if (!_expanded)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.expand_circle_down_outlined),
                label: const Text('Details'),
                onPressed: () => setState(() => _expanded = true),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Required skills (${offer.requirements.length}):',
                    style: GoogleFonts.robotoCondensed(
                        fontSize: 17.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _expanded = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final req in offer.requirements)
                  _RequirementChip(
                    skill: game.content.skill(req.skillId),
                    required: req.level,
                    teamLevel: game.engine.bestLevel(
                        state,
                        _selected.isEmpty ? const [kPlayerId] : _selected,
                        req.skillId),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Assign ${offer.requiredPeople} '
              '${offer.requiredPeople == 1 ? 'person' : 'people'}:',
              style: GoogleFonts.robotoCondensed(
                  fontWeight: FontWeight.bold, fontSize: 17.sp),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
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
                child: Text(blocker, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () => game.rejectOffer(offer.id),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: blocker != null
                      ? null
                      : () {
                          if (game.acceptOffer(offer.id, _selected.toList())) {
                            widget.onAccepted();
                          }
                        },
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ],
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
    return Chip(
      side: BorderSide(color: ok ? Colors.green : Colors.red),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${skill.name} (level $required)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            teamLevel == 0
                ? 'Nobody has this skill'
                : 'Team best: level $teamLevel',
            style: TextStyle(color: ok ? Colors.green : Colors.red),
          ),
        ],
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
    return ChoiceChip(
      selected: selected,
      onSelected: busy ? null : (_) => onTap(),
      avatar: isPlayer
          ? const Icon(Icons.person_outline)
          : RandomAvatar(name, width: 24, height: 24),
      label: Text(busy ? '$name (busy)' : name),
    );
  }
}

class OfferLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const OfferLabel({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.robotoCondensed(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
