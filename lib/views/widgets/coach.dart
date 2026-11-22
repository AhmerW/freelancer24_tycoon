import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:random_avatar/random_avatar.dart';

/// Home tabs, as used by [CoachTip.tab].
abstract final class HomeTabs {
  static const skills = 0;
  static const world = 1;
  static const upgrades = 2;
  static const goals = 3;
}

class CoachTip {
  final String text;

  /// Tab to open when the tip is tapped.
  final int tab;

  const CoachTip(this.text, this.tab);
}

/// Picks the most useful hint for where the player is. Derived from the game
/// state, so it needs no saving and moves on by itself.
CoachTip? coachTipFor(GameState s, GameCubit game) {
  final contracts = s.stats.contractsCompleted;
  final skills = s.skillLevels.length;
  final html = s.skillLevel(game.content.startingSkill.id);

  if (s.achievementsToClaim > 0) {
    return const CoachTip(
        'You reached a goal! Grab your reward in GOALS.', HomeTabs.goals);
  }
  if (s.contractsReadyToCollect > 0) {
    return const CoachTip(
        'Ka-ching! A job is done. Open the city and COLLECT your pay.',
        HomeTabs.world);
  }
  if (s.stats.rebrands == 0 && game.engine.rebrandRecommended(s)) {
    final x = game.engine.rebrandIncomeMultiplier(s).toStringAsFixed(1);
    return CoachTip(
        'Your name is worth a lot now! REBRAND in the World tab: start over '
        'with x$x income forever.',
        HomeTabs.world);
  }
  final graduated = contracts >= 3 && skills >= 3 && s.hiredCount > 0;
  if (graduated) return null;

  if (contracts == 0 && !s.contracts.any((c) => !c.isOffer)) {
    return const CoachTip(
        'Welcome, freelancer! Tap Berlin and accept your first job.',
        HomeTabs.world);
  }
  if (contracts == 0) {
    return const CoachTip(
        'Your job is running! Meanwhile, UPGRADE HTML in Skills to earn more every second.',
        HomeTabs.skills);
  }
  if (skills == 1 && html < 5) {
    return CoachTip('Level HTML to 5 (now $html) to learn Website Development.',
        HomeTabs.skills);
  }
  if (skills == 1) {
    return const CoachTip(
        'HTML is level 5! Learn Website Development in Skills.',
        HomeTabs.skills);
  }
  if (skills == 2) {
    return const CoachTip(
        'A new career track opened: Writing & Content! Check Skills.',
        HomeTabs.skills);
  }
  final chair =
      s.upgrades.values.every((u) => u.itemIndex == 0 && u.level == 1);
  if (chair && s.balance >= 50) {
    return const CoachTip(
        'Treat yourself: office UPGRADES boost your income forever.',
        HomeTabs.upgrades);
  }
  if (s.hiredCount == 0 && s.balance >= 750) {
    return const CoachTip(
        'You can afford a desk! Hire your first employee in the city TEAM tab.',
        HomeTabs.world);
  }
  if (contracts < 3) {
    return const CoachTip(
        'Keep taking jobs: they pay way more than passive income.',
        HomeTabs.world);
  }
  return null;
}

/// The coach: a friendly face with a speech bubble above the tab bar.
class Coach extends StatefulWidget {
  final ValueChanged<int> onOpenTab;

  const Coach({super.key, required this.onOpenTab});

  @override
  State<Coach> createState() => _CoachState();
}

class _CoachState extends State<Coach> {
  String? _dismissed;

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final tip =
        context.select((GameCubit c) => coachTipFor(c.state, game)?.text);
    final full = coachTipFor(game.state, game);
    final visible = tip != null && tip != _dismissed && full != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axisAlignment: 1,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: ValueKey(tip),
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: GestureDetector(
                onTap: () => widget.onOpenTab(full.tab),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: GameColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: GameColors.ink, width: 2.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: RandomAvatar('Coach Robin',
                          width: 48, height: 48, trBackground: true),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: 0, end: -4, duration: 900.ms),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GameColors.ink, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                                color: GameColors.panelShade,
                                offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(tip,
                                  style: GameFonts.body(
                                      size: 13, weight: FontWeight.w800)),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close,
                                  size: 18, color: GameColors.ink),
                              onPressed: () => setState(() => _dismissed = tip),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideX(
                      begin: -0.1, duration: 350.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
            ),
    );
  }
}
