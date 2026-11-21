import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/daily/daily_reward_dialog.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/settings/settings_dialog.dart';

/// Height of the HUD row, without the status bar.
const double kHudHeight = 60;

/// Top bar shown on every screen: money, energy and settings.
class GameHud extends StatelessWidget {
  /// Optional widget before the money (e.g. a back button).
  final Widget? leading;

  const GameHud({super.key, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GameColors.hud,
        border: Border(bottom: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kHudHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                const Expanded(child: MoneyPill()),
                const SizedBox(width: 10),
                const EnergyPill(),
                const SizedBox(width: 8),
                const DailyRewardButton(),
                const SizedBox(width: 6),
                GameButton(
                  tone: GameTone.blue,
                  height: 40,
                  width: 40,
                  icon: Icons.settings,
                  fontSize: 16,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark rounded pill with a round icon overlapping its left edge.
class _HudPill extends StatelessWidget {
  final Widget icon;
  final Widget child;
  final String tooltip;

  const _HudPill(
      {required this.icon, required this.child, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: SizedBox(
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 14),
              padding: const EdgeInsets.only(left: 22, right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A3D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B5BA0), width: 2),
              ),
              alignment: Alignment.centerLeft,
              child: child,
            ),
            icon,
          ],
        ),
      ),
    );
  }
}

class MoneyPill extends StatelessWidget {
  const MoneyPill({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.select((GameCubit c) => c.state.balance);
    final income = context.select((GameCubit c) => c.incomePerSecond);
    return CoinTarget(
      child: _HudPill(
        tooltip: 'Your skills earn ${dollar(income)} every second, '
            'even while you are away (at half speed).',
        icon: const CoinIcon(size: 34),
        child: Row(
          children: [
            Expanded(
              child: RollingNumber(
                value: balance,
                format: dollar,
                builder: (text) => StrokeText(text, size: 18, maxLines: 1),
              ),
            ),
            StrokeText('+${dollar(income)}/s',
                size: 11, color: const Color(0xFF9BF08A)),
          ],
        ),
      ),
    );
  }
}

class EnergyPill extends StatelessWidget {
  const EnergyPill({super.key});

  @override
  Widget build(BuildContext context) {
    final energy = context.select((GameCubit c) => c.state.energy);
    final regen = context
        .select((GameCubit c) => c.engine.energyRegenPerSecond(c.state) * 60);
    const max = Balance.maxEnergy;
    return _HudPill(
      tooltip: 'Energy: working on a contract yourself costs energy. '
          'It refills by ${regen.toStringAsFixed(1)} per minute. '
          'Coffee upgrades make it refill faster.',
      icon: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [
              Color(0xFFF0D9FF),
              GameColors.energy,
              GameColors.energyDark
            ],
            stops: [0, 0.55, 1],
          ),
          border: Border.all(color: const Color(0xFF3D1475), width: 2.5),
        ),
        child: const Icon(Icons.bolt, color: Colors.white, size: 22, shadows: [
          Shadow(color: Color(0xFF3D1475), offset: Offset(0, 1.5)),
        ]),
      ),
      child: SizedBox(
        width: 74,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GameProgressBar(
              value: energy / max,
              tone: GameTone.purple,
              height: 20,
            ),
            StrokeText('${energy.floor()}/${max.toInt()}', size: 13),
          ],
        ),
      ),
    );
  }
}
