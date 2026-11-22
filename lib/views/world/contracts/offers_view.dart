import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:freelancer24_tycoon/views/world/contracts/offer_view.dart';

class OffersView extends StatelessWidget {
  final LocationDef location;
  final VoidCallback onAccepted;

  const OffersView(this.location, {super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    // VIP first: it is the one with a clock.
    final offers = [...game.state.offersAt(location.id)]
      ..sort((a, b) => (b.golden ? 1 : 0) - (a.golden ? 1 : 0));
    final nextIn =
        game.state.locations[location.id]!.nextOfferAt.difference(game.now());
    final max = location.maxOffers;

    if (offers.isEmpty) {
      return EmptyState(
        icon: Icons.mark_email_unread_outlined,
        message: 'No offers right now.\n'
            'New clients will reach out in ${formatDuration(nextIn)}.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        for (final offer in offers)
          OfferView(
            key: ValueKey(offer.id),
            offer: offer,
            location: location,
            onAccepted: onAccepted,
          ),
        if (offers.length < max && !nextIn.isNegative)
          Padding(
            padding: const EdgeInsets.all(12),
            child: StrokeText(
              'Next client in ${formatDuration(nextIn)}',
              size: 16,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
