import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/locations/location_view.dart';
import 'package:freelancer24_tycoon/views/locations/stats_view.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationsView extends StatefulWidget {
  /// Width / height of `assets/images/worldmap.png`.
  static const double mapAspectRatio = 1280 / 800;

  const LocationsView({super.key});

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  int? _openLocationId;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final unlocked =
        context.select((GameCubit c) => c.state.locations.keys.toSet());
    final ready = context.select((GameCubit c) => {
          for (final c in c.state.contracts)
            if (c.isCompleted) c.locationId
        });

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 130),
              AspectRatio(
                aspectRatio: LocationsView.mapAspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/worldmap.png',
                          fit: BoxFit.fill,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                      for (final LocationDef loc in game.content.locations)
                        Positioned(
                          left: constraints.maxWidth * loc.widthMultiplier,
                          top: constraints.maxHeight * loc.heightMultiplier,
                          child: _MapMarker(
                            location: loc,
                            unlocked: unlocked.contains(loc.id),
                            hasPayToCollect: ready.contains(loc.id),
                            onTap: () =>
                                setState(() => _openLocationId = loc.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Expanded(child: StatsView()),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _openLocationId == null
                ? const SizedBox.shrink()
                : LocationView(
                    key: ValueKey(_openLocationId),
                    game.content.location(_openLocationId!),
                    onClose: () => setState(() => _openLocationId = null),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final LocationDef location;
  final bool unlocked;
  final bool hasPayToCollect;
  final VoidCallback onTap;

  const _MapMarker({
    required this.location,
    required this.unlocked,
    required this.hasPayToCollect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Badge(
        isLabelVisible: hasPayToCollect,
        label: const Text('\$'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: unlocked
                ? Colors.green.withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!unlocked)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.lock, size: 11, color: Colors.white),
                ),
              Text(
                location.abbreviation,
                style: GoogleFonts.sansita(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
