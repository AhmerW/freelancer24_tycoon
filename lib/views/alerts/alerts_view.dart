import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/alert_cubit.dart';
import 'package:freelancer24_tycoon/game/game_notice.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:random_avatar/random_avatar.dart';

class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  static Color _color(NoticeKind kind) => switch (kind) {
        NoticeKind.success => Colors.green.shade700,
        NoticeKind.error => Colors.red.shade700,
        NoticeKind.info => Colors.blueGrey.shade700,
      };

  static IconData _icon(NoticeKind kind) => switch (kind) {
        NoticeKind.success => Icons.check_circle_outline,
        NoticeKind.error => Icons.error_outline,
        NoticeKind.info => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final notices = context.watch<AlertCubit>().state;
    return SizedBox(
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final notice in notices)
            Container(
              key: ValueKey(notice.id),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
              decoration: BoxDecoration(
                color: _color(notice.kind).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: notice.avatarSeed != null
                        ? RandomAvatar(notice.avatarSeed!,
                            width: 28, height: 28, trBackground: true)
                        : Icon(_icon(notice.kind), color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            notice.title,
                            style: GoogleFonts.robotoCondensed(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (notice.message.isNotEmpty)
                          Text(
                            notice.message,
                            style: GoogleFonts.robotoCondensed(
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        context.read<AlertCubit>().dismiss(notice.id),
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }
}
