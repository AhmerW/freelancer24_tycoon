import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/widgets/game_hud.dart';
import 'package:freelancer24_tycoon/views/world/contracts/contracts_view.dart';
import 'package:freelancer24_tycoon/views/world/contracts/offers_view.dart';
import 'package:freelancer24_tycoon/views/world/team/employees_view.dart';
import 'package:freelancer24_tycoon/views/world/world_view.dart';

/// A city: its offers, running contracts and team, each in a tab.
class CityPage extends StatefulWidget {
  final LocationDef location;

  const CityPage(this.location, {super.key});

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final unlocked = context
        .select((GameCubit c) => c.state.isLocationUnlocked(location.id));
    final offers =
        context.select((GameCubit c) => c.state.offersAt(location.id).length);
    final running = context.select(
        (GameCubit c) => c.state.runningContractsAt(location.id).length);
    final ready = context.select((GameCubit c) => c.state
        .runningContractsAt(location.id)
        .where((c) => c.isCompleted)
        .length);
    final staff =
        context.select((GameCubit c) => c.state.hiredAt(location.id).length);

    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            GameHud(
              leading: GameButton(
                tone: GameTone.red,
                height: 40,
                width: 40,
                icon: Icons.arrow_back,
                fontSize: 16,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  IconBadge(
                    tone: GameTone.blue,
                    size: 52,
                    child: CityIcon(location),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StrokeText(location.city.toUpperCase(), size: 28),
                        Text(
                          '${location.country} · contracts pay ${location.rate}x',
                          style: GameFonts.body(color: Colors.white, size: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Expanded(child: _LockedCity(location))
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    for (final (i, label, badge) in [
                      (0, 'Offers $offers', 0),
                      (1, 'Jobs $running', ready),
                      (2, 'Team $staff', 0),
                    ]) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _CityTab(
                          label: label,
                          selected: _tabs.index == i,
                          badge: badge,
                          onTap: () => _tabs.animateTo(i),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    OffersView(location, onAccepted: () => _tabs.animateTo(1)),
                    ContractsView(location),
                    EmployeesView(location),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CityTab extends StatelessWidget {
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _CityTab({
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = selected ? GameTone.yellow : GameTone.blue;
    return Bouncy(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tone.top, tone.bottom],
              ),
              border: Border.all(color: GameColors.ink, width: 2),
              boxShadow: [
                BoxShadow(color: tone.lip, offset: const Offset(0, 3))
              ],
            ),
            child: StrokeText(label, size: 15),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: GameColors.bad,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: StrokeText('$badge', size: 13),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.85, end: 1.1, duration: 500.ms),
            ),
        ],
      ),
    );
  }
}

class _LockedCity extends StatelessWidget {
  final LocationDef location;

  const _LockedCity(this.location);

  @override
  Widget build(BuildContext context) {
    final canAfford =
        context.select((GameCubit c) => c.state.balance >= location.price);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GamePanel(
          title: 'LOCKED',
          titleTone: GameTone.grey,
          titleTrailing: const Icon(Icons.lock, color: Colors.white),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(Icons.flight_takeoff,
                      size: 64, color: Color(0xFF2E8BEA))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -6, duration: 1100.ms),
              const SizedBox(height: 12),
              Text(location.message,
                  textAlign: TextAlign.center, style: GameFonts.body(size: 15)),
              const SizedBox(height: 18),
              Builder(
                builder: (buttonContext) => GameButton(
                  tone: GameTone.green,
                  height: 58,
                  shine: canAfford,
                  onPressed: canAfford
                      ? () {
                          if (context
                              .read<GameCubit>()
                              .unlockLocation(location.id)) {
                            Fx.of(buttonContext).confetti(buttonContext);
                          }
                        }
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StrokeText('OPEN OFFICE', size: 18),
                      const SizedBox(width: 10),
                      PriceLabel(location.price, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
