import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ContractView extends StatelessWidget {
  final Contract contract;
  final DateTime now;

  const ContractView({super.key, required this.contract, required this.now});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final done = contract.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: done ? Colors.amber.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: RandomAvatar(contract.client,
                  trBackground: true, width: 50, height: 50),
              title: Text(
                'Contract with ${contract.client}',
                style: TextStyle(fontSize: 17.sp),
              ),
              subtitle: Text(done
                  ? 'Finished! Pay: ${dollar(contract.netPay)}'
                  : 'Finishes in ${formatDuration(contract.remaining(now))}'
                      ' · ${dollar(contract.netPay)}'),
            ),
            LinearProgressIndicator(value: contract.progress(now)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final id in contract.assignees)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: id == kPlayerId
                        ? const CircleAvatar(
                            radius: 16, child: Icon(Icons.person_outline))
                        : RandomAvatar(
                            game.state.employee(id)?.name ?? '?',
                            width: 32,
                            height: 32,
                          ),
                  ),
                const Spacer(),
                done
                    ? FilledButton(
                        onPressed: () => game.collectContract(contract.id),
                        child: const Text('Collect pay'),
                      )
                    : TextButton(
                        onPressed: () => game.cancelContract(contract.id),
                        child: const Text('Cancel contract'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
