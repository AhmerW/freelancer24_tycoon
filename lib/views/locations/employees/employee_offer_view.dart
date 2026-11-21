import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// A job applicant card.
class EmployeeOfferView extends StatefulWidget {
  final Employee employee;
  final LocationDef location;
  final bool canHire;
  final VoidCallback onHire;
  final VoidCallback onReject;

  const EmployeeOfferView(
    this.employee, {
    super.key,
    required this.location,
    required this.canHire,
    required this.onHire,
    required this.onReject,
  });

  @override
  State<EmployeeOfferView> createState() => _EmployeeOfferViewState();
}

class _EmployeeOfferViewState extends State<EmployeeOfferView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    final content = context.read<GameCubit>().content;
    final color = Colors.primaries[e.id % Colors.primaries.length];

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(alpha: 0.3),
                  child: RandomAvatar(e.name,
                      width: 56, height: 56, trBackground: true),
                ),
                title: Text(
                  e.name,
                  style: GoogleFonts.robotoCondensed(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text('Age ${e.age} · ${widget.location.city}'),
                trailing: IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded
                      ? Icons.close_outlined
                      : Icons.expand_circle_down_outlined),
                ),
              ),
              if (_expanded) ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    OfferLabel(
                        icon: Icons.payments_outlined,
                        color: color,
                        text: 'Wage: ',
                        value: '${dollar(e.wagePerHour)}/h'),
                    OfferLabel(
                        icon: Icons.receipt_long_outlined,
                        color: color,
                        text: 'Hire cost: ',
                        value: dollar(e.hireCost)),
                    OfferLabel(
                        icon: Icons.percent_rounded,
                        color: color,
                        text: 'Cut per contract: ',
                        value: '${e.cut}%'),
                    OfferLabel(
                        icon: Icons.remove_circle_outline,
                        color: Colors.black,
                        text: 'Termination cost: ',
                        value: dollar(e.fireCost)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in e.skills.entries)
                      Chip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: color),
                        ),
                        label:
                            Text('${content.skill(s.key).name} lvl ${s.value}'),
                      ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onReject,
                      child: Text('Reject ${e.name}'),
                    ),
                    ElevatedButton(
                      onPressed: widget.canHire ? widget.onHire : null,
                      child: Text('Hire for ${dollar(e.hireCost)}'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OfferLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String value;

  const OfferLabel({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 7),
        RichText(
          text: TextSpan(
            text: text,
            style: GoogleFonts.robotoCondensed(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.roboto(color: Colors.black, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
