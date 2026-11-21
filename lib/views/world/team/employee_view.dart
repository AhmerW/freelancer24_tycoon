import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:random_avatar/random_avatar.dart';

/// Avatar in a round frame.
class PersonAvatar extends StatelessWidget {
  final String name;
  final double size;

  const PersonAvatar(this.name, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFBFE3FF),
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.ink, width: 2),
        ),
        padding: const EdgeInsets.all(3),
        child:
            RandomAvatar(name, width: size, height: size, trBackground: true),
      );
}

/// A hired employee.
class EmployeeView extends StatelessWidget {
  final Employee employee;
  final VoidCallback onFire;

  const EmployeeView(this.employee, {super.key, required this.onFire});

  @override
  Widget build(BuildContext context) {
    final content = context.read<GameCubit>().content;
    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(employee.name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(employee.name, size: 19),
                    Text(
                      employee.isBusy ? 'On a job' : 'Ready for work',
                      style: GameFonts.body(
                          size: 13,
                          color: employee.isBusy
                              ? const Color(0xFFE65100)
                              : const Color(0xFF2B8A1C)),
                    ),
                  ],
                ),
              ),
              GameButton.small(
                tone: GameTone.red,
                label: 'FIRE',
                onPressed: employee.isBusy ? null : () => _confirmFire(context),
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
                    icon: Icons.school,
                    label: '${content.skill(s.key).name} ${s.value}',
                    color: const Color(0xFF6A2DB8)),
              StatChip(
                  icon: Icons.attach_money,
                  label: '${formatMoney(employee.wagePerHour)}/h',
                  color: const Color(0xFF2B8A1C),
                  tooltip: 'Wage'),
              StatChip(
                  icon: Icons.percent,
                  label: '${employee.cut}%',
                  color: const Color(0xFFE65100),
                  tooltip: 'Cut of each job they work on'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmFire(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fire ${employee.name}?'),
        content: Text('Severance costs ${dollar(employee.fireCost)}.',
            style: GameFonts.body()),
        actions: [
          GameButton.small(
              tone: GameTone.blue,
              label: 'KEEP',
              onPressed: () => Navigator.pop(context, false)),
          GameButton.small(
              tone: GameTone.red,
              label: 'FIRE',
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (yes == true) onFire();
  }
}
