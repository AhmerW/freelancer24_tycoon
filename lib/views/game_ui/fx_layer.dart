import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

/// Full-screen overlay for game effects: flying coins, floating text and
/// confetti. Lives above the navigator so effects survive page changes.
///
/// Use `Fx.of(context).coinBurst(context)` from any widget.
class FxLayer extends StatefulWidget {
  final Widget child;

  const FxLayer({super.key, required this.child});

  @override
  State<FxLayer> createState() => FxController();
}

class FxController extends State<FxLayer> {
  final _random = math.Random();
  final List<Widget> _effects = [];
  int _nextKey = 0;

  /// Money displays currently on screen. Coins fly to the newest one (the
  /// page on top).
  final List<GlobalKey> _moneyTargets = [];

  void registerMoneyTarget(GlobalKey key) => _moneyTargets.add(key);
  void unregisterMoneyTarget(GlobalKey key) => _moneyTargets.remove(key);

  /// Bumped whenever coins land, so the money display can do a little pop.
  final ValueNotifier<int> moneyPulse = ValueNotifier(0);

  Offset? _centerOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final layer = this.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || layer == null) return null;
    return layer.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void _add(Widget Function(Key key, VoidCallback done) build) {
    final key = ValueKey(_nextKey++);
    late Widget effect;
    effect = build(key, () {
      if (mounted) setState(() => _effects.remove(effect));
    });
    setState(() => _effects.add(effect));
  }

  /// Coins fly from [from] to the money display.
  void coinBurst(BuildContext from, {int coins = 10}) {
    final start = _centerOf(from);
    final targetContext =
        _moneyTargets.isEmpty ? null : _moneyTargets.last.currentContext;
    final end = targetContext == null ? null : _centerOf(targetContext);
    if (start == null || end == null) return;
    HapticFeedback.mediumImpact();
    for (var i = 0; i < coins; i++) {
      final spread = Offset(
        (_random.nextDouble() - 0.5) * 120,
        (_random.nextDouble() - 0.8) * 100,
      );
      _add((key, done) => _FlyingCoin(
            key: key,
            start: start,
            control: start + spread,
            end: end,
            delay: Duration(milliseconds: i * 45),
            onDone: () {
              moneyPulse.value++;
              done();
            },
          ));
    }
  }

  /// Text that pops up above [from] and floats away.
  void floatText(BuildContext from, String text,
      {Color color = Colors.white, double size = 26}) {
    final start = _centerOf(from);
    if (start == null) return;
    _add((key, done) => _FloatingText(
        key: key,
        at: start,
        text: text,
        color: color,
        size: size,
        onDone: done));
  }

  /// A burst of confetti from [from] (or the top of the screen).
  void confetti([BuildContext? from]) {
    final at = from == null
        ? Offset((context.size?.width ?? 0) / 2, 120)
        : _centerOf(from);
    if (at == null) return;
    HapticFeedback.heavyImpact();
    _add((key, done) => _ConfettiBurst(key: key, at: at, onDone: done));
  }

  @override
  void dispose() {
    moneyPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Fx(
      controller: this,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(child: Stack(children: [..._effects])),
          ),
        ],
      ),
    );
  }
}

class Fx extends InheritedWidget {
  final FxController controller;

  const Fx({super.key, required this.controller, required super.child});

  static FxController of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Fx>()!.controller;

  @override
  bool updateShouldNotify(Fx oldWidget) => false;
}

/// Wraps the money display: registers it as the coin target and pops it
/// when coins land.
class CoinTarget extends StatefulWidget {
  final Widget child;

  const CoinTarget({super.key, required this.child});

  @override
  State<CoinTarget> createState() => _CoinTargetState();
}

class _CoinTargetState extends State<CoinTarget> {
  final _key = GlobalKey();
  FxController? _fx;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fx = Fx.of(context);
    if (fx != _fx) {
      _fx?.unregisterMoneyTarget(_key);
      _fx = fx..registerMoneyTarget(_key);
    }
  }

  @override
  void dispose() {
    _fx?.unregisterMoneyTarget(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: ValueListenableBuilder<int>(
        valueListenable: _fx!.moneyPulse,
        builder: (context, pulse, child) => TweenAnimationBuilder<double>(
          key: ValueKey(pulse),
          tween: Tween(begin: pulse == 0 ? 1 : 1.12, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _FlyingCoin extends StatefulWidget {
  final Offset start;
  final Offset control;
  final Offset end;
  final Duration delay;
  final VoidCallback onDone;

  const _FlyingCoin({
    super.key,
    required this.start,
    required this.control,
    required this.end,
    required this.delay,
    required this.onDone,
  });

  @override
  State<_FlyingCoin> createState() => _FlyingCoinState();
}

class _FlyingCoinState extends State<_FlyingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward().whenComplete(widget.onDone);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (_c.value == 0) return const SizedBox.shrink();
        // First burst outwards, then swoop into the wallet.
        final t = _c.value;
        final burst = Curves.easeOut.transform((t / 0.35).clamp(0, 1));
        final fly =
            Curves.easeInCubic.transform(((t - 0.35) / 0.65).clamp(0, 1));
        final p1 = Offset.lerp(widget.start, widget.control, burst)!;
        final p = Offset.lerp(p1, widget.end, fly)!;
        final size = 26 * (1 - 0.3 * fly);
        return Positioned(
          left: p.dx - size / 2,
          top: p.dy - size / 2,
          child: Transform.rotate(
            angle: t * math.pi * 2,
            child: CoinIcon(size: size),
          ),
        );
      },
    );
  }
}

class _FloatingText extends StatefulWidget {
  final Offset at;
  final String text;
  final Color color;
  final double size;
  final VoidCallback onDone;

  const _FloatingText({
    super.key,
    required this.at,
    required this.text,
    required this.color,
    required this.size,
    required this.onDone,
  });

  @override
  State<_FloatingText> createState() => _FloatingTextState();
}

class _FloatingTextState extends State<_FloatingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final pop = Curves.elasticOut.transform((t / 0.4).clamp(0, 1));
        final fade = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
        return Positioned(
          left: widget.at.dx - 150,
          width: 300,
          top: widget.at.dy - 30 - 70 * Curves.easeOut.transform(t),
          child: Opacity(
            opacity: fade.clamp(0, 1),
            child: Transform.scale(scale: 0.4 + 0.6 * pop, child: child),
          ),
        );
      },
      child: Center(
        child: StrokeText(widget.text,
            size: widget.size,
            color: widget.color,
            textAlign: TextAlign.center),
      ),
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  final Offset at;
  final VoidCallback onDone;

  const _ConfettiBurst({super.key, required this.at, required this.onDone});

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst> {
  final _controller =
      ConfettiController(duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _controller.play();
    Future.delayed(const Duration(seconds: 4), widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.at.dx,
      top: widget.at.dy,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0.6,
        numberOfParticles: 18,
        maxBlastForce: 28,
        minBlastForce: 10,
        gravity: 0.25,
        colors: const [
          GameColors.gold,
          Color(0xFF6CC4FF),
          Color(0xFF8BE55B),
          Color(0xFFFF8A73),
          Color(0xFFD29BFF),
        ],
      ),
    );
  }
}
