import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:random_avatar/random_avatar.dart';

class ContractView extends StatelessWidget {
  final Contract contract;
  final DateTime now;

  const ContractView({super.key, required this.contract, required this.now});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final done = contract.isCompleted;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: done ? const Color(0xFFFFF8E1) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RandomAvatar(contract.client,
                    trBackground: true, width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contract with ${contract.client}',
                          style: text.titleMedium),
                      Text(
                        done
                            ? 'Done! Your pay is ready.'
                            : '${formatDuration(contract.remaining(now))} left',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(dollar(contract.netPay),
                    style: text.titleMedium?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: contract.progress(now),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final id in contract.assignees)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: id == kPlayerId
                        ? const CircleAvatar(
                            radius: 16, child: Icon(Icons.person, size: 18))
                        : RandomAvatar(game.state.employee(id)?.name ?? '?',
                            width: 32, height: 32),
                  ),
                const Spacer(),
                if (done)
                  FilledButton.icon(
                    icon: const Icon(Icons.payments),
                    onPressed: () => game.collectContract(contract.id),
                    label: const Text('Collect'),
                  )
                else
                  TextButton(
                    onPressed: () => _confirmCancel(context, game),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, GameCubit game) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this contract?'),
        content: const Text("You won't get paid and spent energy is lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel contract'),
          ),
        ],
      ),
    );
    if (yes == true) game.cancelContract(contract.id);
  }
}
