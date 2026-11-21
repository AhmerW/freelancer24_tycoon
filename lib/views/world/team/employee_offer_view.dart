import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:freelancer24_tycoon/views/world/team/employee_view.dart';

/// A job applicant card.
class EmployeeOfferView extends StatelessWidget {
  final Employee employee;
  final bool canHire;
  final bool Function() onHire;
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

    return GamePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(e.name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(e.name, size: 19),
                    Text('Age ${e.age} · wants ${e.cut}% of each job',
                        style: GameFonts.body(size: 12)),
                    if (e.expiresIn(context.read<GameCubit>().now())
                        case final left?)
                      Text('Leaves in ${formatDuration(left)}',
                          style: GameFonts.body(
                              size: 12, color: const Color(0xFFE65100))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in e.skills.entries)
                StatChip(
                  icon: state.skillLevel(s.key) < s.value
                      ? Icons.auto_awesome
                      : Icons.school,
                  label: '${content.skill(s.key).name} ${s.value}',
                  color: state.skillLevel(s.key) < s.value
                      ? const Color(0xFFE09B00)
                      : const Color(0xFF6A2DB8),
                  tooltip: state.skillLevel(s.key) < s.value
                      ? 'Better than you at this!'
                      : null,
                ),
              StatChip(
                  icon: Icons.attach_money,
                  label: '${formatMoney(e.wagePerHour)}/h',
                  color: const Color(0xFF2B8A1C),
                  tooltip: 'Wage, paid continuously'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GameButton.small(
                tone: GameTone.red,
                label: 'PASS',
                onPressed: onReject,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (buttonContext) => GameButton(
                    tone: GameTone.green,
                    shine: canHire,
                    onPressed: canHire
                        ? () {
                            if (onHire()) {
                              Fx.of(buttonContext).floatText(
                                  buttonContext, 'HIRED!',
                                  sound: Sound.levelup, color: GameColors.gold);
                            }
                          }
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StrokeText('HIRE', size: 17),
                        const SizedBox(width: 8),
                        PriceLabel(e.hireCost),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
