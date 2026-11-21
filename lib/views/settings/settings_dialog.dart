import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final game = context.read<GameCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
            'All your money, skills, cities and employees will be lost. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset game'),
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
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt, color: Colors.red),
            label:
                const Text('Reset game', style: TextStyle(color: Colors.red)),
            onPressed: () => _confirmReset(context),
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            const Text('Debug', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final amount in [1e4, 1e6, 1e9])
              ElevatedButton(
                onPressed: () => game.debugAddMoney(amount),
                child: Text('+\$${amount.toStringAsExponential(0)}'),
              ),
            ElevatedButton(
              onPressed: game.debugRefillEnergy,
              child: const Text('Refill energy'),
            ),
            ElevatedButton(
              onPressed: game.debugNotice,
              child: const Text('Test alert'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
