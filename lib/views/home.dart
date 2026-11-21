import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/skills/skills_view.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrades_view.dart';
import 'package:freelancer24_tycoon/views/widgets/game_hud.dart';
import 'package:freelancer24_tycoon/views/world/world_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final readyToCollect =
        context.select((GameCubit c) => c.state.contractsReadyToCollect);

    return Scaffold(
      body: Column(
        children: [
          const GameHud(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [SkillsView(), WorldView(), UpgradesView()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: readyToCollect > 0,
              label: Text('$readyToCollect'),
              child: const Icon(Icons.public_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: readyToCollect > 0,
              label: Text('$readyToCollect'),
              child: const Icon(Icons.public),
            ),
            label: 'World',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Upgrades',
          ),
        ],
      ),
    );
  }
}
