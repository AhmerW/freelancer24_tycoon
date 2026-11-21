import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer24_tycoon/core/save/save_store.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';

import 'helpers.dart';

void main() {
  test('a game in progress survives a save/load round trip', () async {
    final engine = testEngine();
    var s = engine.newGame(t0).copyWith(balance: 1e6);
    final berlin = engine.content.startingLocation.id;
    s = engine.buyEmployeeSlot(s, berlin);
    s = engine.hireCandidate(s, s.candidatesAt(berlin).first.id, t0);
    s = engine.upgradeSkill(s, engine.content.startingSkill.id);
    s = engine.advance(s, t0.add(const Duration(minutes: 3))).state;

    final repo = SaveRepository(MemorySaveStore());
    await repo.save(s);
    final loaded = await repo.load();

    expect(loaded, isNotNull);
    expect(jsonEncode(loaded!.toJson()), jsonEncode(s.toJson()));
  });

  test('campaigns, achievements, applicant expiry and new stats round-trip',
      () async {
    final engine = testEngine();
    final berlin = engine.content.startingLocation.id;
    var s = engine.newGame(t0).copyWith(balance: 1e6);
    s = engine.startCampaign(s, berlin, 'online', t0);
    s = engine.unlockLocation(s, engine.content.locations[1].id, t0);
    s = engine.advance(s, t0.add(const Duration(seconds: 2))).state;
    s = engine.claimAchievement(s, 'cities_2');
    s = s.copyWith(
        stats: s.stats.copyWith(goldenContractsCompleted: 3, campaignsRun: 4));

    final repo = SaveRepository(MemorySaveStore());
    await repo.save(s);
    final loaded = (await repo.load())!;

    expect(jsonEncode(loaded.toJson()), jsonEncode(s.toJson()));
    expect(loaded.campaigns.single.campaignId, 'online');
    expect(loaded.isAchievementUnlocked('campaigns_1'), isTrue);
    expect(loaded.isAchievementClaimed('cities_2'), isTrue);
    expect(loaded.stats.goldenContractsCompleted, 3);
    expect(loaded.stats.campaignsRun, 4);
    expect(loaded.candidatesAt(berlin).first.expiresAt,
        s.candidatesAt(berlin).first.expiresAt);
  });

  test('a save from before campaigns and achievements still loads', () {
    final engine = testEngine();
    final berlin = engine.content.startingLocation.id;
    final json = engine.newGame(t0).copyWith(balance: 123).toJson();
    // Strip everything the old format did not have.
    json
      ..remove('campaigns')
      ..remove('achievementsUnlocked')
      ..remove('achievementsClaimed');
    (json['stats'] as Map)
      ..remove('goldenContractsCompleted')
      ..remove('campaignsRun');
    for (final e in json['employees'] as List) {
      (e as Map).remove('expiresAt');
    }
    final laptop =
        engine.content.upgradeLines.firstWhere((l) => l.category == 'laptop');
    (json['upgrades'] as Map).remove('${laptop.id}');

    final old = GameState.fromJson(jsonDecode(jsonEncode(json)));
    expect(old.balance, 123);
    expect(old.campaigns, isEmpty);
    expect(old.achievementsUnlocked, isEmpty);
    expect(old.achievementsClaimed, isEmpty);
    expect(old.stats.campaignsRun, 0);
    expect(old.candidatesAt(berlin).every((e) => e.expiresAt == null), isTrue);

    // The first tick brings it up to date.
    final now = t0.add(const Duration(seconds: 5));
    final s = engine.advance(old, now).state;
    expect(
        s.upgrades[laptop.id], const UpgradeProgress(itemIndex: 0, level: 1));
    expect(s.candidatesAt(berlin), isNotEmpty);
    expect(
        s.candidatesAt(berlin).every((e) => e.expiresAt!.isAfter(now)), isTrue);
    // Upgrading the new line works right away.
    engine.upgradeItemLevel(old.copyWith(balance: 1e6), laptop.id);
  });

  test('a corrupt save is backed up instead of crashing', () async {
    final store = MemorySaveStore('{"version": 1, "balance": "lots"}');
    final loaded = await SaveRepository(store).load();
    expect(loaded, isNull);
    expect(store.corrupt, hasLength(1));
  });

  test('a save from a newer game version is not loaded', () {
    expect(() => GameState.fromJson({'version': kSaveVersion + 1}),
        throwsFormatException);
  });
}
