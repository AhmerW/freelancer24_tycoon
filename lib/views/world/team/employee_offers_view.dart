import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:freelancer24_tycoon/views/world/team/employee_offer_view.dart';

/// Job applicants in a location.
class EmployeeOffersView extends StatelessWidget {
  final LocationDef location;

  const EmployeeOffersView(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final state = game.state;
    final applicants = state.candidatesAt(location.id);
    final progress = state.locations[location.id]!;
    final freeDesks =
        progress.employeeSlots - state.hiredAt(location.id).length;

    if (applicants.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_outlined,
        message: 'No applicants right now.\nNext one in '
            '${formatDuration(progress.nextCandidateAt.difference(game.now()))}.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        if (freeDesks <= 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Buy a desk in "Your team" before hiring.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (final a in applicants)
          EmployeeOfferView(
            a,
            key: ValueKey(a.id),
            canHire: freeDesks > 0 && state.balance >= a.hireCost,
            onHire: () => game.hireCandidate(a.id),
            onReject: () => game.rejectCandidate(a.id),
          ),
      ],
    );
  }
}
