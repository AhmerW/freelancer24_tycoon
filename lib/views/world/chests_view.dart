import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/game/sfx.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

/// The four gift chest slots on the World tab. Clients sometimes leave a
/// chest when a job is collected; it unlocks over time, one at a time.
class ChestSlots extends StatelessWidget {
  const ChestSlots({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds every tick so the timers count down.
    final state = context.watch<GameCubit>().state;
    final game = context.read<GameCubit>();
    final now = game.now();
    final unlocking =
        state.chests.any((c) => game.engine.isChestUnlocking(c, now));

    return GamePanel(
      title: 'CLIENT GIFTS',
      titleTone: GameTone.yellow,
      titleTrailing:
          StrokeText('${state.chests.length}/${Balance.chestSlots}', size: 18),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < Balance.chestSlots; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: i < state.chests.length
                      ? _ChestSlot(
                          key: ValueKey(state.chests[i].id),
                          chest: state.chests[i],
                          now: now,
                          canStart: !unlocking,
                        )
                      : const _EmptySlot(),
                ),
              ],
            ],
          ),
          if (state.chests.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Finish jobs to earn gift chests. VIP clients always leave one!',
                textAlign: TextAlign.center,
                style: GameFonts.body(size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          decoration: BoxDecoration(
            color: GameColors.panelShade,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: GameColors.ink.withValues(alpha: 0.25), width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.inventory_2_outlined,
              color: GameColors.ink.withValues(alpha: 0.25), size: 28),
        ),
      );
}

class _ChestSlot extends StatelessWidget {
  final Chest chest;
  final DateTime now;

  /// False while another chest is unlocking.
  final bool canStart;

  const _ChestSlot({
    super.key,
    required this.chest,
    required this.now,
    required this.canStart,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final engine = game.engine;
    final def = engine.chestDef(chest);
    final color = Color(def.color);
    final ready = engine.isChestReady(chest, now);
    final unlocking = engine.isChestUnlocking(chest, now);
    final remaining = engine.chestRemaining(chest, now);
    final tone = GameTone.from(color);

    final Widget footer;
    if (ready) {
      footer = StrokeText('OPEN!', size: 15, color: GameColors.gold);
    } else if (unlocking) {
      footer = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameProgressBar(
            value: 1 - remaining.inSeconds / max(1, def.unlockTime.inSeconds),
            tone: GameTone.yellow,
            height: 10,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatDuration(remaining),
                style: GameFonts.display(size: 12, color: GameColors.ink)),
          ),
        ],
      );
    } else {
      footer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(canStart ? Icons.lock_open : Icons.lock,
              size: 12, color: GameColors.ink),
          const SizedBox(width: 2),
          Text(formatDuration(def.unlockTime),
              style: GameFonts.display(size: 12, color: GameColors.ink)),
        ],
      );
    }

    Widget art = ChestArt(color: color, size: 52, glowing: ready);
    if (ready) {
      art = art
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 5, rotation: 0.06, duration: 500.ms)
          .then(delay: 900.ms);
    } else if (unlocking) {
      art = art
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -3, duration: 700.ms, curve: Curves.easeInOut);
    }

    return Bouncy(
      onTap: () => _onTap(context, ready: ready, unlocking: unlocking),
      child: AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ready
                  ? [const Color(0xFFFFF4C2), const Color(0xFFFFD25E)]
                  : [Colors.white, tone.top.withValues(alpha: 0.45)],
            ),
            border: Border.all(
                color: ready ? GameColors.goldDark : GameColors.ink,
                width: ready ? 3 : 2),
            boxShadow: [BoxShadow(color: tone.lip, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Expanded(child: Center(child: art)),
              // The timer bar needs a bounded width; only text may scale down.
              unlocking
                  ? SizedBox(width: double.infinity, child: footer)
                  : FittedBox(child: footer),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context,
      {required bool ready, required bool unlocking}) {
    final game = context.read<GameCubit>();
    if (ready) {
      final opening = game.openChest(chest.id);
      if (opening != null) showChestOpening(context, opening);
    } else if (unlocking) {
      Sfx.instance.play(Sound.tap);
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: game,
          child: _ChestInfoDialog(chest: chest),
        ),
      );
    }
  }
}

/// What a locked chest can contain, with a button to start unlocking it.
class _ChestInfoDialog extends StatelessWidget {
  final Chest chest;

  const _ChestInfoDialog({required this.chest});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    final engine = game.engine;
    final def = engine.chestDef(chest);
    final now = game.now();
    final busy = game.state.chests
        .any((c) => c.id != chest.id && engine.isChestUnlocking(c, now));
    final minCash = max(def.minCash,
        engine.incomePerSecond(game.state) * def.cashIncomeSeconds * 0.8);

    Widget line(Widget icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(width: 30, child: Center(child: icon)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: GameFonts.display(size: 16, color: GameColors.ink)),
              ),
            ],
          ),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: GamePanel(
        title: def.name.toUpperCase(),
        titleTone: GameTone.from(Color(def.color)),
        titleTrailing: GameButton.small(
          tone: GameTone.red,
          icon: Icons.close,
          width: 36,
          onPressed: () => Navigator.of(context).pop(),
        ),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: ChestArt(color: Color(def.color), size: 96)),
            const SizedBox(height: 12),
            line(const CoinIcon(size: 22), '${dollar(minCash)} or more'),
            if (def.energy > 0)
              line(const Icon(Icons.bolt, color: GameColors.energy, size: 26),
                  '+${def.energy.round()} energy'),
            if (def.skillLevels > 0)
              line(
                  const Icon(Icons.school, color: GameColors.good, size: 24),
                  '${def.skillLevels} free skill level'
                  '${def.skillLevels == 1 ? '' : 's'}'),
            const SizedBox(height: 14),
            GameButton(
              tone: busy ? GameTone.grey : GameTone.green,
              icon: Icons.lock_clock,
              label: busy
                  ? 'ANOTHER CHEST IS UNLOCKING'
                  : 'UNLOCK · ${formatDuration(def.unlockTime)}',
              fontSize: busy ? 14 : 18,
              onPressed: busy
                  ? null
                  : () {
                      if (game.startChestUnlock(chest.id)) {
                        Sfx.instance.play(Sound.click);
                        Navigator.of(context).pop();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showChestOpening(BuildContext context, ChestOpening opening) {
  final game = context.read<GameCubit>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: game,
      child: ChestOpeningDialog(opening),
    ),
  );
}

/// The chest shakes, pops open and shows its loot one item at a time.
class ChestOpeningDialog extends StatefulWidget {
  final ChestOpening opening;

  const ChestOpeningDialog(this.opening, {super.key});

  @override
  State<ChestOpeningDialog> createState() => _ChestOpeningDialogState();
}

class _ChestOpeningDialogState extends State<ChestOpeningDialog> {
  bool _open = false;
  final _chestKey = GlobalKey();
  final _cashKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Sfx.instance.play(Sound.whoosh);
    Future.delayed(const Duration(milliseconds: 1100), _pop);
  }

  void _pop() {
    if (!mounted || _open) return;
    HapticFeedback.heavyImpact();
    setState(() => _open = true);
    final fx = Fx.of(context);
    final chestContext = _chestKey.currentContext;
    if (chestContext != null) fx.confetti(chestContext);
    // Coins fly to the wallet once the cash line has appeared.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final cashContext = _cashKey.currentContext;
      if (cashContext != null && cashContext.mounted) {
        fx.coinBurst(cashContext, coins: 14);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opening;
    final content = context.read<GameCubit>().content;
    final color = Color(o.chest.color);

    Widget chest = KeyedSubtree(
      key: _chestKey,
      child: ChestArt(color: color, size: 150, open: _open, glowing: _open),
    );
    if (!_open) {
      chest = chest
          .animate()
          .scaleXY(
              begin: 0.3, end: 1, duration: 350.ms, curve: Curves.easeOutBack)
          .then()
          .shake(hz: 8, rotation: 0.1, duration: 700.ms);
    } else {
      chest = chest.animate().scaleXY(
          begin: 1.25, end: 1, duration: 400.ms, curve: Curves.elasticOut);
    }

    final rewards = <Widget>[
      _RewardRow(
        key: _cashKey,
        icon: const CoinIcon(size: 30),
        text: '+${dollar(o.cash)}',
        color: GameColors.gold,
      ),
      if (o.energy > 0)
        _RewardRow(
          icon: const Icon(Icons.bolt, color: GameColors.energy, size: 32),
          text: '+${o.energy.round()} energy',
          color: const Color(0xFFE2C2FF),
        ),
      for (final e in o.skillLevels.entries)
        _RewardRow(
          icon: const Icon(Icons.school, color: GameColors.good, size: 30),
          text: '${content.skill(e.key).name} +${e.value}',
          color: const Color(0xFFC8F5B8),
        ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _pop,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StrokeText(o.chest.name.toUpperCase(), size: 30, color: color),
            const SizedBox(height: 10),
            SizedBox(height: 170, child: Center(child: chest)),
            const SizedBox(height: 12),
            if (_open) ...[
              for (var i = 0; i < rewards.length; i++)
                rewards[i]
                    .animate(delay: (150 + i * 220).ms)
                    .fadeIn(duration: 200.ms)
                    .scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack)
                    .callback(
                        duration: 1.ms,
                        callback: (_) => Sfx.instance
                            .play(i == 0 ? Sound.coin : Sound.ding)),
              const SizedBox(height: 18),
              GameButton(
                tone: GameTone.green,
                height: 54,
                width: 200,
                label: 'AWESOME!',
                onPressed: () => Navigator.of(context).pop(),
              ).animate(delay: (300 + rewards.length * 220).ms).fadeIn(),
            ] else
              StrokeText('Tap to open', size: 18, color: Colors.white)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;

  const _RewardRow(
      {super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GameColors.hud,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 10),
            Flexible(child: StrokeText(text, size: 22, color: color)),
          ],
        ),
      );
}

/// A treasure chest drawn in code, tinted with [color].
class ChestArt extends StatelessWidget {
  final Color color;
  final double size;
  final bool open;
  final bool glowing;

  const ChestArt({
    super.key,
    required this.color,
    this.size = 60,
    this.open = false,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size * 0.9,
        child: CustomPaint(
            painter: _ChestPainter(color, open: open, glowing: glowing)),
      );
}

class _ChestPainter extends CustomPainter {
  final Color color;
  final bool open;
  final bool glowing;

  _ChestPainter(this.color, {required this.open, required this.glowing});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ink = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2, w * 0.04)
      ..strokeJoin = StrokeJoin.round;
    final hsl = HSLColor.fromColor(color);
    final light =
        hsl.withLightness((hsl.lightness + 0.18).clamp(0, 0.92)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.16).clamp(0.05, 1)).toColor();
    const metal = Color(0xFFFFD54A);
    const metalDark = Color(0xFFC98A00);

    if (glowing) {
      canvas.drawCircle(
        Offset(w / 2, h * 0.5),
        w * 0.55,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFF3B0).withValues(alpha: 0.9),
            const Color(0xFFFFF3B0).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(
              center: Offset(w / 2, h * 0.5), radius: w * 0.55)),
      );
    }

    if (open) {
      // Lid tipped back behind the chest, then the treasure inside.
      final backLid = Path()
        ..moveTo(w * 0.1, h * 0.46)
        ..lineTo(w * 0.16, h * 0.08)
        ..quadraticBezierTo(w * 0.5, -h * 0.02, w * 0.84, h * 0.08)
        ..lineTo(w * 0.9, h * 0.46)
        ..close();
      canvas.drawPath(backLid, Paint()..color = dark);
      canvas.drawPath(
          Path()
            ..moveTo(w * 0.16, h * 0.4)
            ..lineTo(w * 0.2, h * 0.14)
            ..quadraticBezierTo(w * 0.5, h * 0.06, w * 0.8, h * 0.14)
            ..lineTo(w * 0.84, h * 0.4)
            ..close(),
          Paint()..color = const Color(0xFF3A2410));
      canvas.drawPath(backLid, ink);
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
            Offset(w * (0.2 + i * 0.12), h * (0.44 - (i % 2) * 0.05)),
            w * 0.08,
            Paint()..color = i.isEven ? const Color(0xFFFFE680) : metal);
      }
      canvas.drawCircle(Offset(w * 0.5, h * 0.33), w * 0.09,
          Paint()..color = const Color(0xFFFFE680));
    }

    // Body.
    final body = RRect.fromLTRBR(
        w * 0.08, h * 0.45, w * 0.92, h * 0.95, Radius.circular(w * 0.07));
    canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, dark],
          ).createShader(body.outerRect));
    // Planks.
    final plank = Paint()
      ..color = dark.withValues(alpha: 0.6)
      ..strokeWidth = max(1, w * 0.02);
    canvas.drawLine(Offset(w * 0.1, h * 0.7), Offset(w * 0.9, h * 0.7), plank);

    // Metal bands on the body.
    for (final x in [0.22, 0.78]) {
      final band =
          Rect.fromLTRB(w * (x - 0.05), h * 0.45, w * (x + 0.05), h * 0.95);
      canvas.drawRect(band, Paint()..color = metal);
      canvas.drawRect(
          band,
          Paint()
            ..color = metalDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    canvas.drawRRect(body, ink);

    if (open) return;

    // Lid.
    final lid = Path()
      ..moveTo(w * 0.06, h * 0.47)
      ..lineTo(w * 0.06, h * 0.3)
      ..quadraticBezierTo(w * 0.06, h * 0.06, w * 0.5, h * 0.06)
      ..quadraticBezierTo(w * 0.94, h * 0.06, w * 0.94, h * 0.3)
      ..lineTo(w * 0.94, h * 0.47)
      ..close();
    canvas.drawPath(
        lid,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light, color],
          ).createShader(Rect.fromLTRB(0, h * 0.06, w, h * 0.47)));
    // Shine on the lid.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.16, h * 0.28)
        ..quadraticBezierTo(w * 0.18, h * 0.13, w * 0.42, h * 0.12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(2, w * 0.045),
    );
    canvas.save();
    canvas.clipPath(lid);
    for (final x in [0.22, 0.78]) {
      canvas.drawRect(
          Rect.fromLTRB(w * (x - 0.05), 0, w * (x + 0.05), h * 0.47),
          Paint()..color = metal);
    }
    canvas.restore();
    canvas.drawPath(lid, ink);

    // Lock.
    final lock = RRect.fromLTRBR(
        w * 0.4, h * 0.38, w * 0.6, h * 0.62, Radius.circular(w * 0.04));
    canvas.drawRRect(lock, Paint()..color = metal);
    canvas.drawRRect(lock, ink..strokeWidth = max(1.5, w * 0.03));
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.48), w * 0.03, Paint()..color = GameColors.ink);
    canvas.drawRect(Rect.fromLTWH(w * 0.49, h * 0.48, w * 0.02, h * 0.08),
        Paint()..color = GameColors.ink);
  }

  @override
  bool shouldRepaint(_ChestPainter old) =>
      old.color != color || old.open != open || old.glowing != glowing;
}
