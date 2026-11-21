import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';

import 'helpers.dart';

void main() {
  late GameEngine engine;
  late GameContent content;

  setUp(() {
    engine = testEngine();
    content = engine.content;
  });

  GameState rich(GameState s, [double amount = 1e12]) =>
      s.copyWith(balance: amount);

  group('content', () {
    test('has 6 tracks of 7 skills with increasing prices', () {
      expect(content.tracks, hasLength(6));
      expect(content.skills, hasLength(42));
      for (final track in content.tracks) {
        final skills = content.skillsInTrack(track.id);
        expect(skills.map((s) => s.step), [1, 2, 3, 4, 5, 6, 7]);
        for (var i = 1; i < skills.length; i++) {
          expect(skills[i].price, greaterThan(skills[i - 1].price));
        }
      }
      expect(content.skills.map((s) => s.id).toSet(), hasLength(42));
      expect(content.startingSkill.key, 'html');
    });

    test('starting location is the free one', () {
      expect(content.startingLocation.city, 'Berlin');
      expect(content.startingLocation.price, 0);
    });

    test('upgrade lines have an effect each', () {
      final effects = content.upgradeLines.map((l) => l.effect).toSet();
      expect(effects, {UpgradeEffect.income, UpgradeEffect.energyRegen});
    });
  });

  group('new game', () {
    test('starts with first skill, full energy and offers in Berlin', () {
      final s = engine.newGame(t0);
      final berlin = content.startingLocation;
      expect(s.balance, 0);
      expect(s.energy, Balance.maxEnergy);
      expect(s.skillLevels, {content.startingSkill.id: 1});
      expect(s.offersAt(berlin.id), hasLength(berlin.maxOffers));
      expect(s.candidatesAt(berlin.id), hasLength(berlin.maxEmployeeOffers));
      expect(s.locations[berlin.id]!.employeeSlots, 0);
    });

    test('without staff, every offer can be done by the player alone', () {
      for (var seed = 0; seed < 50; seed++) {
        final e = testEngine(seed: seed);
        // A mid-game player with several skills at various levels.
        var s = e.newGame(t0).copyWith(
          skillLevels: {0: 12, 1: 7, 2: 3, 3: 1},
          contracts: const [],
        );
        s = e.advance(s, t0.add(const Duration(seconds: 1))).state;
        for (final offer in s.offersAt(content.startingLocation.id)) {
          expect(offer.requiredPeople, 1);
          expect(offer.requirements, isNotEmpty);
          expect(e.teamCovers(s, offer, const [kPlayerId]), isTrue,
              reason:
                  'seed $seed: ${offer.requirements.map((r) => r.toJson())}');
        }
      }
    });
  });

  group('time', () {
    test('passive income accrues per second', () {
      final s = engine.newGame(t0);
      final income = engine.incomePerSecond(s);
      expect(income, greaterThan(0));
      final next = engine.advance(s, t0.add(const Duration(seconds: 10))).state;
      expect(next.balance, closeTo(income * 10, 1e-9));
    });

    test('energy regenerates and is capped', () {
      final s = engine.newGame(t0).copyWith(energy: 10);
      final after =
          engine.advance(s, t0.add(const Duration(seconds: 36))).state;
      expect(after.energy,
          closeTo(10 + 36 * engine.energyRegenPerSecond(s), 1e-9));
      final full = engine.advance(s, t0.add(const Duration(hours: 5))).state;
      expect(full.energy, Balance.maxEnergy);
    });

    test('offline time earns at the offline rate and is capped', () {
      final s = engine.newGame(t0);
      final income = engine.incomePerSecond(s);

      final twoHours = engine.advance(s, t0.add(const Duration(hours: 2)));
      expect(twoHours.awayFor, const Duration(hours: 2));
      expect(twoHours.awayEarnings,
          closeTo(income * 7200 * Balance.offlineIncomeFactor, 1e-6));

      final week = engine.advance(s, t0.add(const Duration(days: 7)));
      expect(
          week.awayEarnings,
          closeTo(
              income *
                  Balance.maxOfflineDuration.inSeconds *
                  Balance.offlineIncomeFactor,
              1e-6));
    });

    test('a clock that jumps backwards does not break the game', () {
      final s = engine.newGame(t0).copyWith(balance: 50);
      final r = engine.advance(s, t0.subtract(const Duration(hours: 1)));
      expect(r.state.balance, 50);
      expect(r.state.lastTick, t0.subtract(const Duration(hours: 1)));
    });
  });

  group('skills', () {
    test('income goes up immediately after an upgrade', () {
      final s = rich(engine.newGame(t0));
      final before = engine.incomePerSecond(s);
      final after = engine.upgradeSkill(s, content.startingSkill.id);
      expect(engine.incomePerSecond(after), greaterThan(before));
    });

    test('upgrading costs money and raises the level', () {
      final skill = content.startingSkill;
      final s = engine.newGame(t0).copyWith(balance: 1000);
      final cost = engine.skillUpgradeCost(skill, 1);
      final next = engine.upgradeSkill(s, skill.id);
      expect(next.skillLevel(skill.id), 2);
      expect(next.balance, closeTo(1000 - cost, 1e-9));
    });

    test('cannot upgrade without money', () {
      final s = engine.newGame(t0);
      expect(() => engine.upgradeSkill(s, content.startingSkill.id),
          throwsA(isA<GameRuleException>()));
    });

    test('unlocking requires the previous skill level', () {
      final second = content.skills[1];
      var s = rich(engine.newGame(t0));
      expect(engine.skillUnlockBlocker(s, second), contains('level'));
      expect(() => engine.unlockSkill(s, second.id),
          throwsA(isA<GameRuleException>()));

      for (var i = 1; i < second.unlockOnPreviousLevel; i++) {
        s = engine.upgradeSkill(s, content.startingSkill.id);
      }
      expect(engine.skillUnlockBlocker(s, second), isNull);
      s = engine.unlockSkill(s, second.id);
      expect(s.skillLevel(second.id), 1);
    });

    test('skills in a track must be learned in order', () {
      final s = rich(engine.newGame(t0));
      final third = content.skillsInTrack('web')[2];
      expect(engine.skillUnlockBlocker(s, third), contains('first'));
      expect(() => engine.unlockSkill(s, third.id),
          throwsA(isA<GameRuleException>()));
    });

    test('tracks open after enough skills are learned', () {
      final writing = content.track('writing');
      final firstWriting = content.skillsInTrack('writing').first;
      var s = rich(engine.newGame(t0));
      expect(engine.isTrackOpen(s, writing), isFalse);
      expect(engine.skillUnlockBlocker(s, firstWriting), contains('Writing'));

      // Learn Website Development (needs HTML at level 5).
      final web = content.skillsInTrack('web');
      for (var i = 1; i < web[1].unlockOnPreviousLevel; i++) {
        s = engine.upgradeSkill(s, web[0].id);
      }
      s = engine.unlockSkill(s, web[1].id);
      expect(s.skillLevels.length, writing.unlockAtSkills);
      expect(engine.isTrackOpen(s, writing), isTrue);
      expect(engine.nextSkills(s).map((k) => k.key),
          containsAll(['javascript', firstWriting.key]));
      s = engine.unlockSkill(s, firstWriting.id);
      expect(s.isSkillUnlocked(firstWriting.id), isTrue);
    });
  });

  group('upgrades', () {
    late UpgradeLineDef chair;
    setUp(() => chair = content.upgradeLines
        .firstWhere((l) => l.effect == UpgradeEffect.income));

    test('levels up until max, then the next item costs its price', () {
      var s = rich(engine.newGame(t0));
      final max = engine.maxItemLevel(s, chair);
      for (var i = 1; i < max; i++) {
        s = engine.upgradeItemLevel(s, chair.id);
      }
      expect(s.upgrades[chair.id]!.level, max);
      expect(() => engine.upgradeItemLevel(s, chair.id),
          throwsA(isA<GameRuleException>()));

      final before = s.balance;
      s = engine.buyNextItem(s, chair.id);
      expect(
          s.upgrades[chair.id], const UpgradeProgress(itemIndex: 1, level: 1));
      expect(s.balance, closeTo(before - chair.items[1].price, 1e-3));
    });

    test('next item is not free and needs the level', () {
      final s = rich(engine.newGame(t0));
      expect(() => engine.buyNextItem(s, chair.id),
          throwsA(isA<GameRuleException>()));
    });

    test('bonus counts finished items and the current level', () {
      var s = rich(engine.newGame(t0));
      expect(engine.upgradeBonus(s, UpgradeEffect.income), chair.items[0].rate);
      final max = engine.maxItemLevel(s, chair);
      for (var i = 1; i < max; i++) {
        s = engine.upgradeItemLevel(s, chair.id);
      }
      s = engine.buyNextItem(s, chair.id);
      expect(engine.upgradeBonus(s, UpgradeEffect.income),
          chair.items[0].rate * max + chair.items[1].rate);
    });
  });

  group('contracts', () {
    GameState withSoloOffer() {
      final s = engine.newGame(t0);
      final berlin = content.startingLocation.id;
      // Make the first offer doable by a level-1 player.
      final offer = s.offersAt(berlin).first;
      final doable = Contract(
        id: offer.id,
        locationId: berlin,
        client: offer.client,
        message: offer.message,
        pay: 100,
        duration: const Duration(minutes: 1),
        energy: 10,
        requiredPeople: 1,
        requirements: [
          SkillRequirement(skillId: content.startingSkill.id, level: 1)
        ],
      );
      return s.copyWith(contracts: [
        for (final c in s.contracts) c.id == offer.id ? doable : c
      ]);
    }

    test('accept, finish, collect', () {
      var s = withSoloOffer();
      final offer = s.offersAt(content.startingLocation.id).first;

      s = engine.acceptOffer(s, offer.id, [kPlayerId], t0);
      expect(s.contract(offer.id)!.isActive, isTrue);
      expect(s.energy, Balance.maxEnergy - 10);
      expect(s.playerBusy, isTrue);

      final half = engine.advance(s, t0.add(const Duration(seconds: 30)));
      expect(half.completed, isEmpty);

      final done =
          engine.advance(half.state, t0.add(const Duration(seconds: 61)));
      expect(done.completed.map((c) => c.id), [offer.id]);
      s = done.state;
      expect(s.contract(offer.id)!.isCompleted, isTrue);
      expect(s.playerBusy, isFalse);

      final before = s.balance;
      s = engine.collectContract(s, offer.id);
      expect(s.balance, closeTo(before + 100, 1e-9));
      expect(s.contract(offer.id), isNull);
      expect(s.stats.contractsCompleted, 1);
    });

    test('the player can only work on one contract at a time', () {
      var s = withSoloOffer();
      final offers = s.offersAt(content.startingLocation.id);
      s = engine.acceptOffer(s, offers.first.id, [kPlayerId], t0);
      expect(() => engine.acceptOffer(s, offers[1].id, [kPlayerId], t0),
          throwsA(isA<GameRuleException>()));
    });

    test('needs the right number of people, skills and energy', () {
      final s = withSoloOffer();
      final offer = s.offersAt(content.startingLocation.id).first;
      expect(() => engine.acceptOffer(s, offer.id, [], t0),
          throwsA(isA<GameRuleException>()));
      expect(
          () => engine.acceptOffer(
              s.copyWith(energy: 2), offer.id, [kPlayerId], t0),
          throwsA(isA<GameRuleException>()));
      final noSkill = s.copyWith(skillLevels: {content.skills[1].id: 1});
      expect(() => engine.acceptOffer(noSkill, offer.id, [kPlayerId], t0),
          throwsA(isA<GameRuleException>()));
    });

    test('a rejected offer is replaced only after the cooldown', () {
      var s = withSoloOffer();
      final berlin = content.startingLocation;
      final offer = s.offersAt(berlin.id).first;
      s = engine.rejectOffer(s, offer.id, t0);
      expect(s.offersAt(berlin.id), hasLength(berlin.maxOffers - 1));

      s = engine.advance(s, t0.add(const Duration(seconds: 5))).state;
      expect(s.offersAt(berlin.id), hasLength(berlin.maxOffers - 1));

      s = engine.advance(s, t0.add(Balance.offerCooldown)).state;
      expect(s.offersAt(berlin.id), hasLength(berlin.maxOffers));
    });

    test('cancelling frees the player and does not pay', () {
      var s = withSoloOffer();
      final offer = s.offersAt(content.startingLocation.id).first;
      s = engine.acceptOffer(s, offer.id, [kPlayerId], t0);
      final before = s.balance;
      s = engine.cancelContract(s, offer.id);
      expect(s.playerBusy, isFalse);
      expect(s.balance, before);
    });
  });

  group('employees', () {
    test('hiring needs a desk, then costs money; wages are paid', () {
      final berlin = content.startingLocation;
      var s = rich(engine.newGame(t0), 1e6);
      final applicant = s.candidatesAt(berlin.id).first;

      expect(() => engine.hireCandidate(s, applicant.id, t0),
          throwsA(isA<GameRuleException>()));

      s = engine.buyEmployeeSlot(s, berlin.id);
      expect(s.locations[berlin.id]!.employeeSlots, 1);

      final before = s.balance;
      s = engine.hireCandidate(s, applicant.id, t0);
      expect(s.hiredAt(berlin.id).map((e) => e.id), [applicant.id]);
      expect(s.balance, closeTo(before - applicant.hireCost, 1e-6));
      expect(s.stats.employeesHired, 1);

      expect(engine.wagesPerSecond(s),
          closeTo(applicant.wagePerHour / 3600, 1e-12));
    });

    test('employees can do contracts without the player, with a cut', () {
      final berlin = content.startingLocation;
      var s = rich(engine.newGame(t0), 1e6);
      s = engine.buyEmployeeSlot(s, berlin.id);
      final worker = s.candidatesAt(berlin.id).first;
      s = engine.hireCandidate(s, worker.id, t0);

      final skillId = worker.skills.keys.first;
      final offer = Contract(
        id: 9999,
        locationId: berlin.id,
        client: 'Test',
        message: '',
        pay: 1000,
        duration: const Duration(minutes: 1),
        energy: 10,
        requiredPeople: 1,
        requirements: [SkillRequirement(skillId: skillId, level: 1)],
      );
      s = s.copyWith(contracts: [...s.contracts, offer]);
      final energyBefore = s.energy;
      s = engine.acceptOffer(s, offer.id, [worker.id], t0);
      expect(s.energy, energyBefore, reason: 'no energy without the player');
      expect(s.contract(offer.id)!.netPay,
          closeTo(1000 * (1 - worker.cut / 100), 1e-9));
      expect(s.employee(worker.id)!.isBusy, isTrue);
      expect(() => engine.fireEmployee(s, worker.id),
          throwsA(isA<GameRuleException>()));

      s = engine.advance(s, t0.add(const Duration(minutes: 2))).state;
      expect(s.employee(worker.id)!.isBusy, isFalse);
      s = engine.fireEmployee(s, worker.id);
      expect(s.employee(worker.id), isNull);
    });

    test('unlocking a location brings offers there', () {
      final mumbai = content.locations[1];
      var s = rich(engine.newGame(t0));
      s = engine.unlockLocation(s, mumbai.id, t0);
      expect(s.isLocationUnlocked(mumbai.id), isTrue);
      expect(s.offersAt(mumbai.id), hasLength(mumbai.maxOffers));
    });
  });
}
