import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_offer_view.dart';

/// Job applicants in a location.
class EmployeeOffersView extends StatelessWidget {
  final LocationDef location;

  const EmployeeOffersView(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final state = game.state;
    final applicants = state.candidatesAt(location.id);
    final freeDesks = state.locations[location.id]!.employeeSlots -
        state.hiredAt(location.id).length;

    if (applicants.isEmpty) {
      final nextIn =
          state.locations[location.id]!.nextCandidateAt.difference(game.now());
      return Center(
        child: Text('No applicants right now. '
            'Next one in ${formatDuration(nextIn)}.'),
      );
    }
    return ListView(
      children: [
        if (freeDesks <= 0)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Buy a desk before you can hire someone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
        for (final a in applicants)
          EmployeeOfferView(
            a,
            key: ValueKey(a.id),
            location: location,
            canHire: freeDesks > 0 && state.balance >= a.hireCost,
            onHire: () => game.hireCandidate(a.id),
            onReject: () => game.rejectCandidate(a.id),
          ),
      ],
    );
  }
}
