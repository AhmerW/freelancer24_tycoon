import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/alert_cubit.dart';
import 'package:freelancer24_tycoon/game/game_notice.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:random_avatar/random_avatar.dart';

/// Game-style banners that drop in below the HUD.
class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  static GameTone _tone(NoticeKind kind) => switch (kind) {
        NoticeKind.success => GameTone.green,
        NoticeKind.error => GameTone.red,
        NoticeKind.info => GameTone.blue,
      };

  static IconData _icon(NoticeKind kind) => switch (kind) {
        NoticeKind.success => Icons.check_circle,
        NoticeKind.error => Icons.error,
        NoticeKind.info => Icons.info,
      };

  @override
  Widget build(BuildContext context) {
    final notices = context.watch<AlertCubit>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final notice in notices)
          GestureDetector(
            key: ValueKey(notice.id),
            onTap: () => context.read<AlertCubit>().dismiss(notice.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_tone(notice.kind).top, _tone(notice.kind).bottom],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GameColors.ink, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: _tone(notice.kind).lip,
                      offset: const Offset(0, 4)),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  notice.avatarSeed != null
                      ? RandomAvatar(notice.avatarSeed!,
                          width: 34, height: 34, trBackground: true)
                      : Icon(_icon(notice.kind),
                          color: Colors.white,
                          size: 30,
                          shadows: const [
                              Shadow(
                                  color: GameColors.ink, offset: Offset(0, 2))
                            ]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StrokeText(notice.title, size: 17),
                        if (notice.message.isNotEmpty)
                          Text(notice.message,
                              style: GameFonts.body(
                                  color: Colors.white, size: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(begin: -0.6, duration: 380.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 150.ms),
          ),
      ],
    );
  }
}
