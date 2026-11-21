import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/widgets/game_hud.dart';
import 'package:freelancer24_tycoon/views/world/contracts/contracts_view.dart';
import 'package:freelancer24_tycoon/views/world/contracts/offers_view.dart';
import 'package:freelancer24_tycoon/views/world/team/employees_view.dart';

/// A city: its offers, running contracts and team, each in a tab.
class CityPage extends StatefulWidget {
  final LocationDef location;

  const CityPage(this.location, {super.key});

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          GameHud(
              leading:
                  BackButton(onPressed: () => Navigator.of(context).pop())),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${location.city}, ${location.country}',
                    style: text.headlineSmall),
                Text(
                  unlocked
                      ? 'Freelance Portal · contracts pay ${location.rate}x'
                      : 'Locked',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          if (!unlocked)
            Expanded(child: _LockedCity(location))
          else ...[
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: 'Offers ($offers)'),
                Tab(
                  child: Badge(
                    isLabelVisible: ready > 0,
                    label: Text('$ready'),
                    offset: const Offset(12, -6),
                    child: Text('Contracts ($running)'),
                  ),
                ),
                Tab(text: 'Team ($staff)'),
              ],
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.lock_outline,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            location.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.lock_open),
            onPressed: canAfford
                ? () => context.read<GameCubit>().unlockLocation(location.id)
                : null,
            label: Text('Open an office for ${dollar(location.price)}'),
          ),
          const SizedBox(height: 8),
          Text('Contracts here pay ${location.rate}x more'),
        ],
      ),
    );
  }
}
