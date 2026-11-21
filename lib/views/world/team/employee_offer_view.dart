import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:random_avatar/random_avatar.dart';

/// A job applicant card.
class EmployeeOfferView extends StatelessWidget {
  final Employee employee;
  final bool canHire;
  final VoidCallback onHire;
  final VoidCallback onReject;

  const EmployeeOfferView(
    this.employee, {
    super.key,
    required this.canHire,
    required this.onHire,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final content = context.read<GameCubit>().content;
    final state = context.read<GameCubit>().state;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RandomAvatar(e.name, width: 44, height: 44, trBackground: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: text.titleMedium),
                      Text('Age ${e.age}', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Skills', style: text.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in e.skills.entries)
                  StatChip(
                    icon: state.isSkillUnlocked(s.key)
                        ? Icons.school_outlined
                        : Icons.auto_awesome,
                    label: '${content.skill(s.key).name} ${s.value}',
                    color: state.skillLevel(s.key) < s.value
                        ? Colors.green.shade800
                        : null,
                    tooltip: state.skillLevel(s.key) < s.value
                        ? 'Better than you at this!'
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatChip(
                    icon: Icons.payments_outlined,
                    label: '${dollar(e.wagePerHour)}/h',
                    tooltip: 'Wage, paid continuously'),
                StatChip(
                    icon: Icons.percent,
                    label: '${e.cut}% cut',
                    tooltip: 'Share of each contract they work on'),
                StatChip(
                    icon: Icons.logout,
                    label: dollar(e.fireCost),
                    tooltip: 'Severance if you fire them'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: onReject, child: const Text('Pass')),
                const Spacer(),
                FilledButton(
                  onPressed: canHire ? onHire : null,
                  child: Text('Hire for ${dollar(e.hireCost)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
