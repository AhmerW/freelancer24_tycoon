import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/world/city_page.dart';
import 'package:freelancer24_tycoon/views/world/stats_view.dart';

void openCity(BuildContext context, LocationDef location) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => CityPage(location)),
  );
}

/// The "World" tab: map, career stats and the list of cities.
class WorldView extends StatelessWidget {
  /// Width / height of `assets/images/worldmap.png`.
  static const double mapAspectRatio = 1280 / 800;

  const WorldView({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<GameCubit>().content;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _WorldMap(),
        const SizedBox(height: 16),
        const StatsView(),
        const SizedBox(height: 24),
        Text('Cities', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final loc in content.locations) CityCard(loc),
      ],
    );
  }
}

class _WorldMap extends StatelessWidget {
  const _WorldMap();

  @override
  Widget build(BuildContext context) {
    final content = context.read<GameCubit>().content;
    final unlocked = context
        .select((GameCubit c) => c.state.locations.keys.toSet().join(','));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: WorldView.mapAspectRatio,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/worldmap.png',
                  fit: BoxFit.fill,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
              for (final loc in content.locations)
                Positioned(
                  left: box.maxWidth * loc.widthMultiplier,
                  top: box.maxHeight * loc.heightMultiplier,
                  child: _MapPin(
                    location: loc,
                    unlocked: unlocked.split(',').contains('${loc.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final LocationDef location;
  final bool unlocked;

  const _MapPin({required this.location, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCity(context, location),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: unlocked
              ? Colors.green.shade700
              : Colors.black.withValues(alpha: 0.55),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(unlocked ? Icons.location_on : Icons.lock,
                size: 11, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              location.abbreviation,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A city row in the World tab.
class CityCard extends StatelessWidget {
  final LocationDef location;

  const CityCard(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.locations != b.locations ||
          a.contracts != b.contracts ||
          a.employees != b.employees ||
          (a.balance >= location.price) != (b.balance >= location.price),
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        final unlocked = state.isLocationUnlocked(location.id);
        final running = state.runningContractsAt(location.id);
        final ready = running.where((c) => c.isCompleted).length;

        final String subtitle;
        if (!unlocked) {
          subtitle = 'Unlock for ${dollar(location.price)} · '
              'contracts pay ${location.rate}x';
        } else {
          final offers = state.offersAt(location.id).length;
          final staff = state.hiredAt(location.id).length;
          subtitle = '$offers offer${offers == 1 ? '' : 's'} · '
              '${running.length} running · '
              '$staff employee${staff == 1 ? '' : 's'}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => openCity(context, location),
            leading: CircleAvatar(
              backgroundColor: unlocked
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: unlocked
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                          'assets/icons/locations/${location.icon}'),
                    )
                  : Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
            ),
            title: Text('${location.city}, ${location.country}'),
            subtitle: Text(subtitle),
            trailing: ready > 0
                ? Badge(
                    label: Text('$ready'),
                    child: const Icon(Icons.payments, color: Colors.green),
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
