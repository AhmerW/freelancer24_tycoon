import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:freelancer24_tycoon/views/daily/daily_reward_dialog.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/goals/goals_view.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_view.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrades_view.dart';
import 'package:freelancer24_tycoon/views/widgets/coach.dart';
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
  void initState() {
    super.initState();
    // Greet returning players with their daily reward.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && context.read<GameCubit>().dailyReward.available) {
          showDailyReward(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final readyToCollect = context.select((GameCubit c) =>
        c.state.contractsReadyToCollect +
        c.state.chests.where((x) => c.engine.isChestReady(x, c.now())).length);
    final goalsToClaim =
        context.select((GameCubit c) => c.state.achievementsToClaim);

    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            const GameHud(),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  SkillsView(),
                  WorldView(),
                  UpgradesView(),
                  GoalsView(),
                ],
              ),
            ),
            Coach(onOpenTab: (i) => setState(() => _tab = i)),
            GameTabBar(
              index: _tab,
              onSelect: (i) => setState(() => _tab = i),
              tabs: [
                const GameTab(icon: Icons.school, label: 'Skills'),
                GameTab(
                    icon: Icons.public, label: 'World', badge: readyToCollect),
                const GameTab(icon: Icons.storefront, label: 'Upgrades'),
                GameTab(
                    icon: Icons.emoji_events,
                    label: 'Goals',
                    badge: goalsToClaim),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameTab {
  final IconData icon;
  final String label;
  final int badge;

  const GameTab({required this.icon, required this.label, this.badge = 0});
}

/// Bottom tab bar: the selected tab lifts up and grows, the others are icons.
class GameTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<GameTab> tabs;

  const GameTabBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A3D),
        border: Border(top: BorderSide(color: Color(0xFF3B5BA0), width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  flex: i == index ? 4 : 3,
                  child: _TabButton(
                    tab: tabs[i],
                    selected: i == index,
                    onTap: () {
                      if (i != index) {
                        HapticFeedback.selectionClick();
                        Sfx.instance.play(Sound.click, volume: 0.8);
                      }
                      onSelect(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final GameTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      tab.icon,
      size: selected ? 34 : 28,
      color: selected ? Colors.white : const Color(0xFF8FA6D6),
      shadows: const [Shadow(color: GameColors.ink, offset: Offset(0, 2))],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        // No overshoot here: margins must not go negative.
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.fromLTRB(3, selected ? 0 : 8, 3, selected ? 4 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6CC4FF), Color(0xFF2E6FD8)],
                )
              : null,
          border: selected ? Border.all(color: GameColors.ink, width: 2) : null,
          boxShadow: selected
              ? const [
                  BoxShadow(color: Color(0xFF1A4CA0), offset: Offset(0, 3))
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: tab.badge > 0,
                backgroundColor: GameColors.bad,
                label: Text('${tab.badge}',
                    style: GameFonts.display(size: 12, color: Colors.white)),
                child: selected
                    ? icon.animate(key: ValueKey(tab.label)).scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 350.ms,
                        curve: Curves.elasticOut)
                    : icon,
              ),
              if (selected) StrokeText(tab.label, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}
