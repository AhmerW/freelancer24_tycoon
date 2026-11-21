import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:random_avatar/random_avatar.dart';

/// A hired employee.
class EmployeeView extends StatelessWidget {
  final Employee employee;
  final VoidCallback onFire;

  const EmployeeView(this.employee, {super.key, required this.onFire});

  @override
  Widget build(BuildContext context) {
    final content = context.read<GameCubit>().content;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RandomAvatar(employee.name, width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: text.titleMedium),
                      Text(
                        employee.isBusy ? 'Working on a contract' : 'Available',
                        style: text.bodySmall?.copyWith(
                            color: employee.isBusy
                                ? Colors.orange.shade800
                                : Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed:
                      employee.isBusy ? null : () => _confirmFire(context),
                  child: const Text('Fire'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in employee.skills.entries)
                  StatChip(
                      icon: Icons.school_outlined,
                      label: '${content.skill(s.key).name} ${s.value}'),
                StatChip(
                    icon: Icons.payments_outlined,
                    label: '${dollar(employee.wagePerHour)}/h',
                    tooltip: 'Wage'),
                StatChip(
                    icon: Icons.percent,
                    label: '${employee.cut}%',
                    tooltip: 'Cut of each contract'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFire(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fire ${employee.name}?'),
        content: Text('Severance costs ${dollar(employee.fireCost)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fire')),
        ],
      ),
    );
    if (yes == true) onFire();
  }
}
