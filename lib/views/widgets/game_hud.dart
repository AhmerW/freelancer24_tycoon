import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/settings/settings_dialog.dart';

/// Height of the HUD row, without the status bar.
const double kHudHeight = 60;

const _tabular = [FontFeature.tabularFigures()];

/// Top bar shown on every screen: money, energy and settings.
class GameHud extends StatelessWidget {
  /// Optional widget before the money (e.g. a back button).
  final Widget? leading;

  const GameHud({super.key, this.leading});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kHudHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 4)],
                const Expanded(child: MoneyPill()),
                const SizedBox(width: 8),
                const EnergyPill(),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ),
                  icon: Icon(Icons.settings_outlined, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  final String tooltip;

  const _Pill(
      {required this.color, required this.child, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }
}

class MoneyPill extends StatelessWidget {
  static const color = Color(0xFF1B5E20);

  const MoneyPill({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.select((GameCubit c) => c.state.balance);
    final income = context.select((GameCubit c) => c.incomePerSecond);
    final text = Theme.of(context).textTheme;
    return _Pill(
      color: const Color(0xFFE2F7D3),
      tooltip: 'Your skills earn ${dollar(income)} every second, '
          'even while you are away (at half speed).',
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dollar(balance),
                  maxLines: 1,
                  style: text.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    fontFeatures: _tabular,
                  ),
                ),
                Text(
                  '+${dollar(income)}/s',
                  maxLines: 1,
                  style: text.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    height: 1.1,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EnergyPill extends StatelessWidget {
  static const color = Color(0xFF8D5A00);

  const EnergyPill({super.key});

  @override
  Widget build(BuildContext context) {
    final energy = context.select((GameCubit c) => c.state.energy);
    final regen = context
        .select((GameCubit c) => c.engine.energyRegenPerSecond(c.state) * 60);
    final text = Theme.of(context).textTheme;
    const max = Balance.maxEnergy;
    return _Pill(
      color: const Color(0xFFFFF0C2),
      tooltip: 'Energy: working on a contract yourself costs energy. '
          'It refills by ${regen.toStringAsFixed(1)} per minute. '
          'Coffee upgrades make it refill faster.',
      child: SizedBox(
        width: 92,
        child: Row(
          children: [
            const Icon(Icons.bolt, color: color, size: 22),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${energy.floor()}/${max.toInt()}',
                    style: text.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      fontFeatures: _tabular,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: energy / max,
                      minHeight: 6,
                      color: const Color(0xFFF2A900),
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
