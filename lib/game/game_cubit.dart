import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/save/save_store.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_notice.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

/// Owns the running game: ticks time forward, runs player actions through the
/// [GameEngine], saves, and reports what happened as [GameNotice]s.
class GameCubit extends Cubit<GameState> {
  static const tickInterval = Duration(seconds: 1);
  static const autosaveInterval = Duration(seconds: 10);

  final GameEngine engine;
  final SaveRepository _saves;
  final DateTime Function() _clock;
  final StreamController<GameNotice> _notices =
      StreamController<GameNotice>.broadcast();

  Timer? _ticker;
  DateTime _lastSave;

  GameCubit({
    required this.engine,
    required SaveRepository saves,
    required GameState initial,
    DateTime Function()? clock,
  })  : _saves = saves,
        _clock = clock ?? DateTime.now,
        _lastSave = (clock ?? DateTime.now)(),
        super(initial);

  GameContent get content => engine.content;
  Stream<GameNotice> get notices => _notices.stream;
  DateTime now() => _clock();

  // ---- Derived values for the UI --------------------------------------------

  double get incomePerSecond => engine.incomePerSecond(state);

  // ---- Time ------------------------------------------------------------------

  /// Starts the game clock. The first tick also applies offline progress.
  void startTicking() {
    _ticker?.cancel();
    tick();
    _ticker = Timer.periodic(tickInterval, (_) => tick());
  }

  void stopTicking() {
    _ticker?.cancel();
    _ticker = null;
  }

  void tick() {
    if (isClosed) return;
    final result = engine.advance(state, now());
    emit(result.state);

    for (final c in result.completed) {
      final city = content.location(c.locationId).city;
      _notify(GameNotice(
        kind: NoticeKind.success,
        title: 'Contract finished',
        message: '${c.client} in $city: collect ${dollar(c.netPay)}',
        avatarSeed: c.client,
        chime: true,
      ));
    }
    _announceAchievements(result.newAchievements);
    if (result.awayFor != null && result.awayEarnings > 0) {
      _notify(GameNotice(
        kind: NoticeKind.info,
        title: 'Welcome back!',
        message: 'You earned ${dollar(result.awayEarnings)} '
            'in ${formatDuration(result.awayFor!)} away',
        lifetime: const Duration(seconds: 8),
        chime: true,
      ));
    }

    if (now().difference(_lastSave) >= autosaveInterval ||
        result.completed.isNotEmpty ||
        result.awayFor != null) {
      save();
    }
  }

  /// Call when the app goes to the background.
  Future<void> onPaused() async {
    stopTicking();
    await save();
  }

  /// Call when the app comes back to the foreground.
  void onResumed() => startTicking();

  Future<void> save() async {
    _lastSave = now();
    await _saves.save(state);
  }

  // ---- Player actions --------------------------------------------------------
  // Each returns true on success. Failures are reported as error notices.

  bool unlockSkill(int skillId) => _run(
        (s) => engine.unlockSkill(s, skillId),
        success: 'Unlocked ${content.skill(skillId).name}!',
      );

  bool upgradeSkill(int skillId) =>
      _run((s) => engine.upgradeSkill(s, skillId));

  bool upgradeItemLevel(int lineId) =>
      _run((s) => engine.upgradeItemLevel(s, lineId));

  bool buyNextItem(int lineId) => _run((s) => engine.buyNextItem(s, lineId));

  bool unlockLocation(int locationId) => _run(
        (s) => engine.unlockLocation(s, locationId, now()),
        success: 'Welcome to ${content.location(locationId).city}!',
      );

  bool buyEmployeeSlot(int locationId) =>
      _run((s) => engine.buyEmployeeSlot(s, locationId));

  bool hireCandidate(int employeeId) {
    final name = state.employee(employeeId)?.name ?? '';
    return _run(
      (s) => engine.hireCandidate(s, employeeId, now()),
      success: 'Hired $name',
      avatarSeed: name,
    );
  }

  bool rejectCandidate(int employeeId) =>
      _run((s) => engine.rejectCandidate(s, employeeId, now()));

  bool fireEmployee(int employeeId) {
    final name = state.employee(employeeId)?.name ?? '';
    return _run(
      (s) => engine.fireEmployee(s, employeeId),
      success: 'Fired $name',
      avatarSeed: name,
    );
  }

  bool acceptOffer(int contractId, List<int> assignees) =>
      _run((s) => engine.acceptOffer(s, contractId, assignees, now()));

  bool rejectOffer(int contractId) =>
      _run((s) => engine.rejectOffer(s, contractId, now()));

  bool cancelContract(int contractId) =>
      _run((s) => engine.cancelContract(s, contractId));

  bool collectContract(int contractId) {
    final pay = state.contract(contractId)?.netPay ?? 0;
    final chestsBefore = state.chests.map((c) => c.id).toSet();
    final ok = _run(
      (s) => engine.collectContract(s, contractId),
      success: 'Collected ${dollar(pay)}',
    );
    if (ok) {
      for (final chest in state.chests) {
        if (chestsBefore.contains(chest.id)) continue;
        _notify(GameNotice(
          kind: NoticeKind.success,
          title: 'The client sent a gift!',
          message: 'You got a ${engine.chestDef(chest).name}. '
              'Open it in the World tab.',
          lifetime: const Duration(seconds: 5),
          chime: true,
        ));
      }
    }
    return ok;
  }

  // ---- Gift chests -----------------------------------------------------------

  bool startChestUnlock(int chestId) =>
      _run((s) => engine.startChestUnlock(s, chestId, now()));

  /// Opens a ready chest; returns what was inside, or null.
  ChestOpening? openChest(int chestId) {
    ChestOpening? opening;
    final ok = _run((s) {
      opening = engine.openChest(s, chestId, now());
      return opening!.state;
    });
    return ok ? opening : null;
  }

  // ---- AI assistant ----------------------------------------------------------

  /// Hires the AI assistant, or upgrades it.
  bool upgradeAi() {
    final hiring = state.aiLevel == 0;
    return _run(
      engine.upgradeAi,
      success: hiring ? 'Your AI assistant is online!' : null,
    );
  }

  // ---- Rebrand ---------------------------------------------------------------

  int get pendingStars => engine.pendingStars(state);

  /// Rebrands (prestige); returns the stars gained, or null.
  int? rebrand() {
    final gained = pendingStars;
    final ok = _run((s) => engine.rebrand(s, now()));
    return ok ? gained : null;
  }

  bool startCampaign(int locationId, String campaignId) => _run(
        (s) => engine.startCampaign(s, locationId, campaignId, now()),
        success:
            '${content.campaignOrNull(campaignId)?.name ?? 'Campaign'} is live!',
      );

  /// Claims an achievement reward; returns the amount paid, or null.
  double? claimAchievement(String id) {
    final before = state.balance;
    final ok = _run((s) => engine.claimAchievement(s, id));
    return ok ? state.balance - before : null;
  }

  DailyRewardStatus get dailyReward => engine.dailyRewardStatus(state, now());

  /// Claims today's daily reward; returns the cash paid, or null.
  double? claimDailyReward() {
    final before = state.balance;
    final ok = _run((s) => engine.claimDailyReward(s, now()));
    return ok ? state.balance - before : null;
  }

  Future<void> resetGame() async {
    await _saves.clear();
    emit(engine.newGame(now()));
    await save();
  }

  // ---- Debug -----------------------------------------------------------------

  void debugAddMoney(double amount) =>
      _run((s) => engine.debugAddMoney(s, amount));

  void debugRefillEnergy() => _run(engine.debugRefillEnergy);

  void debugAddChest() => _run((s) => engine.debugAddChest(s, now()));

  void debugNotice() => _notify(GameNotice(
        kind: NoticeKind.info,
        title: 'Test alert',
        message: 'This is what alerts look like',
      ));

  // ---- Internals -------------------------------------------------------------

  bool _run(
    GameState Function(GameState) action, {
    String? success,
    String? avatarSeed,
  }) {
    try {
      final check = engine.checkAchievements(action(state));
      emit(check.state);
      _announceAchievements(check.unlocked);
    } on GameRuleException catch (e) {
      _notify(GameNotice(
        kind: NoticeKind.error,
        title: e.message,
        lifetime: const Duration(seconds: 3),
      ));
      return false;
    }
    if (success != null) {
      _notify(GameNotice(
        kind: NoticeKind.success,
        title: success,
        avatarSeed: avatarSeed,
      ));
    }
    save();
    return true;
  }

  void _announceAchievements(List<AchievementDef> unlocked) {
    for (final a in unlocked) {
      _notify(GameNotice(
        kind: NoticeKind.success,
        title: 'Achievement: ${a.title}',
        message: 'Claim your reward in Goals!',
        lifetime: const Duration(seconds: 5),
        chime: true,
      ));
    }
  }

  void _notify(GameNotice notice) {
    if (!_notices.isClosed) _notices.add(notice);
  }

  @override
  Future<void> close() async {
    stopTicking();
    await save();
    await _notices.close();
    return super.close();
  }
}
