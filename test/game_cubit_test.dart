import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer24_tycoon/core/save/save_store.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/game/game_notice.dart';

import 'helpers.dart';

void main() {
  late DateTime now;
  late MemorySaveStore store;
  late GameCubit cubit;
  late List<GameNotice> notices;

  setUp(() {
    now = t0;
    store = MemorySaveStore();
    final engine = testEngine();
    cubit = GameCubit(
      engine: engine,
      saves: SaveRepository(store),
      initial: engine.newGame(t0),
      clock: () => now,
    );
    notices = [];
    cubit.notices.listen(notices.add);
  });

  tearDown(() => cubit.close());

  test('ticks move money forward', () {
    now = t0.add(const Duration(seconds: 5));
    cubit.tick();
    expect(cubit.state.balance, greaterThan(0));
  });

  test('a failed action reports an error and changes nothing', () async {
    final before = cubit.state;
    final ok = cubit.upgradeSkill(cubit.content.startingSkill.id);
    await Future<void>.delayed(Duration.zero);
    expect(ok, isFalse);
    expect(cubit.state, same(before));
    expect(notices.single.kind, NoticeKind.error);
  });

  test('successful actions are saved', () async {
    cubit.debugAddMoney(100);
    cubit.upgradeSkill(cubit.content.startingSkill.id);
    await Future<void>.delayed(Duration.zero);
    expect(store.data, isNotNull);
    final saved = await SaveRepository(store).load();
    expect(saved!.skillLevel(cubit.content.startingSkill.id), 2);
  });

  test('coming back after a while shows what was earned', () async {
    now = t0.add(const Duration(hours: 3));
    cubit.onResumed();
    await Future<void>.delayed(Duration.zero);
    expect(notices.any((n) => n.title == 'Welcome back!'), isTrue);
    cubit.stopTicking();
  });
}
