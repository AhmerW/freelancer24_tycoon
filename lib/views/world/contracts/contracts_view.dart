import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:freelancer24_tycoon/views/world/contracts/contract_view.dart';

class ContractsView extends StatelessWidget {
  final LocationDef location;

  const ContractsView(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds every tick, which also drives the countdowns.
    final game = context.watch<GameCubit>();
    final contracts = game.state.runningContractsAt(location.id);
    if (contracts.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        message: 'No contracts running.\nAccept an offer to get to work!',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        for (final c in contracts)
          ContractView(key: ValueKey(c.id), contract: c, now: game.now()),
      ],
    );
  }
}
