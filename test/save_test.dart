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
