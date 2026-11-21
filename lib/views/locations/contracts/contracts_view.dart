import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/contract_view.dart';

class ContractsView extends StatelessWidget {
  final LocationDef location;
  final VoidCallback onBack;

  const ContractsView(this.location, {super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    // Rebuilds every tick, which also drives the countdowns.
    final game = context.watch<GameCubit>();
    final contracts = game.state.runningContractsAt(location.id);
    return Column(
      children: [
        Expanded(
          child: contracts.isEmpty
              ? const Center(child: Text('You have no active contracts'))
              : ListView(
                  children: [
                    for (final c in contracts)
                      ContractView(
                          key: ValueKey(c.id), contract: c, now: game.now()),
                  ],
                ),
        ),
        TextButton(onPressed: onBack, child: const Text('Go back')),
      ],
    );
  }
}
