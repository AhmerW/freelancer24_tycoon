import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/offer_view.dart';

class OffersView extends StatelessWidget {
  final LocationDef location;
  final VoidCallback onBack;
  final VoidCallback onShowContracts;

  const OffersView(
    this.location, {
    super.key,
    required this.onBack,
    required this.onShowContracts,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final offers = game.state.offersAt(location.id);
    final progress = game.state.locations[location.id]!;
    final nextIn = progress.nextOfferAt.difference(game.now());

    return Column(
      children: [
        Expanded(
          child: offers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No offers right now. '
                      'New clients will reach out in ${formatDuration(nextIn)}.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final offer in offers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OfferView(
                          key: ValueKey(offer.id),
                          offer: offer,
                          location: location,
                          onAccepted: onShowContracts,
                        ),
                      ),
                  ],
                ),
        ),
        TextButton(onPressed: onBack, child: const Text('Go back')),
      ],
    );
  }
}
