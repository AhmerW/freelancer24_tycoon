import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final game = context.read<GameCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: Text(
            'All your money, skills, cities and employees will be lost. '
            'This cannot be undone.',
            style: GameFonts.body()),
        actions: [
          GameButton.small(
            tone: GameTone.blue,
            label: 'CANCEL',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          GameButton.small(
            tone: GameTone.red,
            label: 'RESET',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await game.resetGame();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GamePanel(
        title: 'SETTINGS',
        titleTone: GameTone.blue,
        titleTrailing: GameButton.small(
          tone: GameTone.red,
          icon: Icons.close,
          width: 36,
          onPressed: () => Navigator.of(context).pop(),
        ),
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: Sfx.instance.muted,
              builder: (context, muted, _) => GameButton(
                tone: muted ? GameTone.grey : GameTone.green,
                icon: muted ? Icons.volume_off : Icons.volume_up,
                label: muted ? 'SOUND: OFF' : 'SOUND: ON',
                onPressed: () => Sfx.instance.setMuted(!muted),
              ),
            ),
            const SizedBox(height: 12),
            GameButton(
              tone: GameTone.red,
              icon: Icons.restart_alt,
              label: 'RESET GAME',
              onPressed: () => _confirmReset(context),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text('DEBUG',
                  style: GameFonts.display(size: 16, color: GameColors.ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final (amount, label) in [
                    (1e4, '+\$10k'),
                    (1e6, '+\$1M'),
                    (1e9, '+\$1B'),
                  ])
                    GameButton.small(
                      tone: GameTone.yellow,
                      label: label,
                      onPressed: () => game.debugAddMoney(amount),
                    ),
                  GameButton.small(
                    tone: GameTone.purple,
                    icon: Icons.bolt,
                    label: 'ENERGY',
                    onPressed: game.debugRefillEnergy,
                  ),
                  GameButton.small(
                    tone: GameTone.blue,
                    label: 'TEST ALERT',
                    onPressed: game.debugNotice,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
