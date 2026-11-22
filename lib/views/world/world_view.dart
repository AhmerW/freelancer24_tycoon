import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/world/chests_view.dart';
import 'package:freelancer24_tycoon/views/world/city_page.dart';
import 'package:freelancer24_tycoon/views/world/rebrand_view.dart';
import 'package:freelancer24_tycoon/views/world/stats_view.dart';

void openCity(BuildContext context, LocationDef location) {
  Sfx.instance.play(Sound.whoosh, volume: 0.7);
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => CityPage(location),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    ),
  );
}

/// City icon, with a generic fallback for cities without artwork.
class CityIcon extends StatelessWidget {
  final LocationDef location;
  final double size;

  const CityIcon(this.location, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => location.icon.isEmpty
      ? Icon(Icons.location_city, color: Colors.white, size: size * 0.85)
      : Image.asset('assets/icons/locations/${location.icon}',
          width: size, height: size);
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
      children: [
        const ChestSlots(),
        const _WorldMap(),
        const StatsView(),
        const RebrandCard(),
        const SectionTitle('CITIES'),
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
    return GamePanel(
      padding: EdgeInsets.zero,
      color: const Color(0xFF9ED8FF),
      child: AspectRatio(
        aspectRatio: WorldView.mapAspectRatio,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/worldmap.png',
                  fit: BoxFit.fill,
                  color: const Color(0xFF2C6FB8),
                ),
              ),
              // Locked pins first, so unlocked ones are drawn on top.
              for (final loc in [
                ...content.locations
                    .where((l) => !unlocked.split(',').contains('${l.id}')),
                ...content.locations
                    .where((l) => unlocked.split(',').contains('${l.id}')),
              ])
                Positioned(
                  // Keep pins inside the map (they are ~70px wide).
                  left: (box.maxWidth * loc.widthMultiplier)
                      .clamp(0.0, box.maxWidth - 70),
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
    final tone = unlocked ? GameTone.green : GameTone.grey;
    final pin = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone.top, tone.bottom],
        ),
        border: Border.all(color: GameColors.ink, width: 1.5),
        boxShadow: [BoxShadow(color: tone.lip, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(unlocked ? Icons.location_on : Icons.lock,
              size: 11, color: Colors.white),
          const SizedBox(width: 2),
          StrokeText(location.abbreviation, size: 11, strokeWidth: 2),
        ],
      ),
    );
    return Bouncy(
      onTap: () => openCity(context, location),
      child: unlocked
          ? pin.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
              begin: 0, end: -3, duration: 900.ms, curve: Curves.easeInOut)
          : pin,
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
        final unlocked = state.isLocationUnlocked(location.id);
        final running = state.runningContractsAt(location.id);
        final ready = running.where((c) => c.isCompleted).length;
        final offers = state.offersAt(location.id).length;
        final staff = state.hiredAt(location.id).length;

        return Bouncy(
          onTap: () => openCity(context, location),
          child: GamePanel(
            color: unlocked ? GameColors.panel : GameColors.panelShade,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconBadge(
                  tone: unlocked ? GameTone.blue : GameTone.grey,
                  size: 54,
                  child: unlocked
                      ? CityIcon(location)
                      : const Icon(Icons.lock, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StrokeText(location.city, size: 20),
                      Text(
                        unlocked
                            ? '$offers offers · ${running.length} running · '
                                '$staff staff'
                            : '${location.country} · pays ${location.rate}x',
                        style: GameFonts.body(size: 12),
                      ),
                    ],
                  ),
                ),
                if (!unlocked)
                  _PriceTag(location.price,
                      affordable: state.balance >= location.price)
                else if (ready > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GameColors.gold,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GameColors.ink, width: 2),
                    ),
                    child: StrokeText('COLLECT!', size: 15),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 0.92, end: 1.08, duration: 500.ms)
                else
                  const Icon(Icons.chevron_right,
                      color: GameColors.ink, size: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double price;
  final bool affordable;

  const _PriceTag(this.price, {required this.affordable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: affordable ? GameColors.good : const Color(0xFF5A6478),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 20),
          const SizedBox(width: 4),
          StrokeText(formatMoney(price), size: 15),
        ],
      ),
    );
  }
}
