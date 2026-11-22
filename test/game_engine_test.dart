import 'dart:io';

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
      expect(effects, UpgradeEffect.values.toSet());
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

  group('new content', () {
    test('8 cities with names, messages and map positions', () {
      expect(content.locations, hasLength(8));
      expect(content.locations.map((l) => l.id).toSet(), hasLength(8));
      for (final l in content.locations) {
        expect(l.names.length, greaterThanOrEqualTo(7), reason: l.city);
        expect(l.messages, isNotEmpty, reason: l.city);
        expect(l.widthMultiplier, inInclusiveRange(0, 1));
        expect(l.heightMultiplier, inInclusiveRange(0, 1));
      }
      final added = content.locations.where((l) => l.id >= 4).toList();
      expect(added.map((l) => l.city),
          containsAll(['Sao Paulo', 'London', 'Tokyo', 'Sydney']));
      for (final l in added) {
        expect(l.icon, isEmpty, reason: 'no PNG yet: UI uses a fallback');
        expect(l.messages.length, inInclusiveRange(4, 6));
      }
    });

    test('a newly added city can be unlocked and gets offers', () {
      final tokyo = content.locations.firstWhere((l) => l.city == 'Tokyo');
      var s = rich(engine.newGame(t0));
      s = engine.unlockLocation(s, tokyo.id, t0);
      expect(s.offersAt(tokyo.id), hasLength(tokyo.maxOffers));
      expect(s.candidatesAt(tokyo.id), hasLength(tokyo.maxEmployeeOffers));
    });

    test('marketing campaigns and achievements are loaded', () {
      expect(content.campaigns.map((c) => c.id), ['flyers', 'radio', 'online']);
      for (final c in content.campaigns) {
        expect(c.description.length, lessThanOrEqualTo(70), reason: c.id);
        expect(c.minCost, greaterThan(0));
      }
      expect(content.achievements.length, greaterThanOrEqualTo(20));
      final types = content.achievements.map((a) => a.condition.type).toSet();
      expect(types, containsAll(AchievementConditionType.values));
    });

    test('the laptop line has 6 items with icons on disk', () {
      final laptop =
          content.upgradeLines.firstWhere((l) => l.category == 'laptop');
      expect(laptop.effect, UpgradeEffect.contractSpeed);
      expect(laptop.items, hasLength(6));
      for (final item in laptop.items) {
        expect(File('assets/icons/upgrades/laptop/${item.icon}').existsSync(),
            isTrue,
            reason: item.icon);
      }
    });
  });

  group('applicant expiry', () {
    test('applicants leave after a while and are replaced', () {
      final berlin = content.startingLocation;
      var s = engine.newGame(t0);
      final first = s.candidatesAt(berlin.id);
      for (final c in first) {
        final life = c.expiresAt!.difference(t0);
        expect(life, greaterThanOrEqualTo(Balance.candidateLifetime * 0.75));
        expect(life, lessThanOrEqualTo(Balance.candidateLifetime * 1.25));
      }

      s = engine.advance(s, t0.add(const Duration(minutes: 5))).state;
      expect(
          s.candidatesAt(berlin.id).map((e) => e.id), first.map((e) => e.id));

      final later = t0.add(Balance.candidateLifetime * 1.3);
      s = engine.advance(s, later).state;
      final ids = s.candidatesAt(berlin.id).map((e) => e.id).toSet();
      expect(ids.intersection(first.map((e) => e.id).toSet()), isEmpty);
      expect(ids, hasLength(berlin.maxEmployeeOffers));
      for (final c in s.candidatesAt(berlin.id)) {
        expect(c.expiresAt!.isAfter(later), isTrue);
      }
    });

    test('hired employees never expire', () {
      final berlin = content.startingLocation;
      var s = rich(engine.newGame(t0), 1e6);
      s = engine.buyEmployeeSlot(s, berlin.id);
      final worker = s.candidatesAt(berlin.id).first;
      s = engine.hireCandidate(s, worker.id, t0);
      expect(s.employee(worker.id)!.expiresAt, isNull);
      s = engine.advance(s, t0.add(const Duration(hours: 5))).state;
      expect(s.employee(worker.id)!.isHired, isTrue);
    });

    test('an applicant who has left cannot be hired', () {
      final berlin = content.startingLocation;
      var s = rich(engine.newGame(t0), 1e6);
      s = engine.buyEmployeeSlot(s, berlin.id);
      final applicant = s.candidatesAt(berlin.id).first;
      expect(() => engine.hireCandidate(s, applicant.id, applicant.expiresAt!),
          throwsA(isA<GameRuleException>()));
    });

    test('applicants from old saves get a fresh expiry time', () {
      final berlin = content.startingLocation;
      var s = engine.newGame(t0);
      s = s.copyWith(employees: [
        for (final e in s.employees) e.copyWith(expiresAt: () => null)
      ]);
      final later = t0.add(const Duration(hours: 3));
      s = engine.advance(s, later).state;
      final applicants = s.candidatesAt(berlin.id);
      expect(applicants, hasLength(berlin.maxEmployeeOffers));
      for (final c in applicants) {
        expect(c.expiresIn(later)!,
            greaterThanOrEqualTo(Balance.candidateLifetime * 0.75));
      }
    });
  });

  group('marketing', () {
    late int berlin;
    CampaignDef campaign(String id) => content.campaignOrNull(id)!;
    setUp(() => berlin = content.startingLocation.id);

    test('costs seconds of income with a minimum', () {
      final flyers = campaign('flyers');
      final s = engine.newGame(t0);
      expect(engine.campaignCost(s, flyers), flyers.minCost);
      final pro = s.copyWith(skillLevels: {0: 400});
      expect(
          engine.campaignCost(pro, flyers),
          closeTo(
              engine.incomePerSecond(pro) * flyers.costIncomeSeconds, 1e-6));
    });

    test('starting a campaign charges, counts and runs until it ends', () {
      final radio = campaign('radio');
      var s = rich(engine.newGame(t0), 1000);
      final cost = engine.campaignCost(s, radio);
      s = engine.startCampaign(s, berlin, 'radio', t0);
      expect(s.balance, closeTo(1000 - cost, 1e-9));
      expect(s.stats.campaignsRun, 1);
      expect(engine.activeCampaigns(s, berlin, t0).single.campaignId, 'radio');
      expect(engine.activeCampaign(s, berlin, 'radio', t0)!.endsAt,
          t0.add(radio.duration));

      final end = t0.add(radio.duration);
      s = engine.advance(s, end).state;
      expect(engine.activeCampaigns(s, berlin, end), isEmpty);
      expect(s.campaigns, isEmpty, reason: 'ended campaigns are removed');
      s = engine.startCampaign(s, berlin, 'radio', end);
      expect(s.stats.campaignsRun, 2);
    });

    test('friendly errors: locked city, already running, no money', () {
      final s = rich(engine.newGame(t0), 1e6);
      final mumbai = content.locations[1];
      expect(
          () => engine.startCampaign(s, mumbai.id, 'flyers', t0),
          throwsA(isA<GameRuleException>()
              .having((e) => e.message, 'message', contains(mumbai.city))));

      final running = engine.startCampaign(s, berlin, 'flyers', t0);
      expect(
          () => engine.startCampaign(running, berlin, 'flyers', t0),
          throwsA(isA<GameRuleException>()
              .having((e) => e.message, 'message', contains('already'))));
      // A different campaign in the same city is fine.
      engine.startCampaign(running, berlin, 'online', t0);

      expect(
          () => engine.startCampaign(engine.newGame(t0), berlin, 'online', t0),
          throwsA(isA<GameRuleException>()
              .having((e) => e.message, 'message', contains('money'))));
      expect(() => engine.startCampaign(s, berlin, 'nope', t0),
          throwsA(isA<GameRuleException>()));
    });

    test('flyers bring extra offers right away, and only while running', () {
      final flyers = campaign('flyers');
      final max = content.startingLocation.maxOffers;
      var s = rich(engine.newGame(t0), 1e6);
      expect(s.offersAt(berlin), hasLength(max));
      s = engine.startCampaign(s, berlin, 'flyers', t0);
      expect(engine.maxOffersAt(s, berlin, t0), max + flyers.extraOffers);
      expect(s.offersAt(berlin), hasLength(max + flyers.extraOffers));

      // After it ends, taken offers are not refilled beyond the normal max.
      final end = t0.add(flyers.duration);
      s = engine.advance(s, end).state;
      for (final offer in s.offersAt(berlin).take(flyers.extraOffers + 1)) {
        s = engine.rejectOffer(s, offer.id, end);
      }
      s = engine.advance(s, end.add(const Duration(minutes: 10))).state;
      expect(s.offersAt(berlin), hasLength(max));
    });

    test('radio ads make new offers arrive sooner', () {
      final radio = campaign('radio');
      var s = rich(engine.newGame(t0), 1e6);
      s = engine.startCampaign(s, berlin, 'radio', t0);
      // Radio also adds an offer slot; fill it first.
      s = engine.advance(s, t0.add(const Duration(seconds: 1))).state;
      final full = s.offersAt(berlin).length;
      final cooldown = engine.offerCooldownAt(s, berlin, t0);
      // Radio stacks with the internet line's (small, starting) bonus.
      expect(
          cooldown,
          Balance.offerCooldown *
              (radio.offerCooldownMultiplier / engine.offerSpeedMultiplier(s)));

      final now = t0.add(const Duration(seconds: 1));
      s = engine.rejectOffer(s, s.offersAt(berlin).first.id, now);
      s = engine.advance(s, now.add(cooldown)).state;
      expect(s.offersAt(berlin), hasLength(full));
      expect(cooldown, lessThan(Balance.offerCooldown));
    });

    test('online ads raise pay and the golden chance', () {
      final online = campaign('online');
      GameState fresh(GameEngine e) => e
          .newGame(t0)
          .copyWith(balance: 1e6, contracts: const [], skillLevels: {0: 30});

      var goldenWith = 0, goldenWithout = 0, total = 0;
      for (var seed = 0; seed < 150; seed++) {
        // Same seed and state: the same random draws, so offers line up.
        final a = testEngine(seed: seed);
        final b = testEngine(seed: seed);
        final base = a.advance(fresh(a), t0.add(const Duration(seconds: 1)));
        var boosted = b.startCampaign(fresh(b), berlin, 'online', t0);
        boosted = b.advance(boosted, t0.add(const Duration(seconds: 1))).state;
        final plain = base.state.offersAt(berlin);
        final ads = boosted.offersAt(berlin);
        expect(ads, hasLength(plain.length));
        for (var i = 0; i < plain.length; i++) {
          total++;
          if (plain[i].golden) goldenWithout++;
          if (ads[i].golden) goldenWith++;
          if (plain[i].golden) expect(ads[i].golden, isTrue);
          final ratio = ads[i].pay / plain[i].pay;
          final expected = online.payMultiplier *
              (ads[i].golden && !plain[i].golden
                  ? Balance.goldenMultiplier
                  : 1);
          expect(ratio, closeTo(expected, 1e-9));
        }
      }
      expect(goldenWith / total, closeTo(Balance.goldenChance + 0.1, 0.06));
      expect(goldenWith, greaterThan(goldenWithout));
    });
  });

  group('laptop upgrades', () {
    test('a faster laptop shortens new contracts but keeps their pay', () {
      final laptop =
          content.upgradeLines.firstWhere((l) => l.category == 'laptop');
      GameState withLaptop(UpgradeProgress p) => engine.newGame(t0).copyWith(
            contracts: const [],
            skillLevels: {0: 30, 1: 10, 2: 5},
            upgrades: {
              for (final line in content.upgradeLines)
                line.id: line.id == laptop.id
                    ? p
                    : const UpgradeProgress(itemIndex: 0, level: 1)
            },
          );
      final slow = withLaptop(const UpgradeProgress(itemIndex: 0, level: 1));
      final fast = withLaptop(UpgradeProgress(
          itemIndex: laptop.items.length - 1,
          level: Balance.lastUpgradeItemMaxLevel));
      expect(engine.contractSpeedMultiplier(slow),
          closeTo(1 + laptop.items[0].rate / 100, 1e-9));
      final speed = engine.contractSpeedMultiplier(fast);
      expect(speed, greaterThan(2));

      final berlin = content.startingLocation.id;
      final later = t0.add(const Duration(seconds: 1));
      final a = testEngine(seed: 3).advance(slow, later).state.offersAt(berlin);
      final b = testEngine(seed: 3).advance(fast, later).state.offersAt(berlin);
      for (var i = 0; i < a.length; i++) {
        expect(b[i].pay, a[i].pay);
        final base =
            a[i].duration.inSeconds * engine.contractSpeedMultiplier(slow);
        expect(b[i].duration.inSeconds, closeTo(base / speed, 1.01));
      }
    });
  });

  group('achievements', () {
    AchievementDef def(String id) => content.achievementOrNull(id)!;

    GameState collectOne(GameState s, {bool golden = false}) {
      final berlin = content.startingLocation.id;
      final contract = Contract(
        id: 9999,
        locationId: berlin,
        client: 'Test',
        message: '',
        pay: 100,
        duration: const Duration(seconds: 10),
        energy: 5,
        requiredPeople: 1,
        requirements: [
          SkillRequirement(skillId: content.startingSkill.id, level: 1)
        ],
        golden: golden,
        status: ContractStatus.completed,
        acceptedAt: t0,
        assignees: const [kPlayerId],
        netPay: 100,
      );
      return engine.collectContract(
          s.copyWith(contracts: [...s.contracts, contract]), contract.id);
    }

    test('nothing is unlocked in a new game', () {
      final s = engine.newGame(t0);
      expect(s.achievementsUnlocked, isEmpty);
      final check = engine.checkAchievements(s);
      expect(check.unlocked, isEmpty);
      expect(check.state, same(s));
    });

    test('unlocks on the next tick and is reported once', () {
      var s = collectOne(engine.newGame(t0));
      final r = engine.advance(s, t0.add(const Duration(seconds: 1)));
      expect(r.newAchievements.map((a) => a.id), ['first_contract']);
      expect(r.state.isAchievementUnlocked('first_contract'), isTrue);
      expect(r.state.achievementsToClaim, 1);
      final again = engine.advance(r.state, t0.add(const Duration(seconds: 2)));
      expect(again.newAchievements, isEmpty);
    });

    test('claiming pays the reward once', () {
      final a = def('first_contract');
      var s = collectOne(engine.newGame(t0));
      s = engine.advance(s, t0.add(const Duration(seconds: 1))).state;
      final before = s.balance;
      final reward = engine.achievementReward(s, a);
      expect(reward, greaterThanOrEqualTo(a.rewardMin));
      s = engine.claimAchievement(s, a.id);
      expect(s.balance, closeTo(before + reward, 1e-9));
      expect(s.isAchievementClaimed(a.id), isTrue);
      expect(s.achievementsToClaim, 0);
      expect(() => engine.claimAchievement(s, a.id),
          throwsA(isA<GameRuleException>()));
    });

    test('rewards scale with income', () {
      final a = def('first_contract');
      final s = engine.newGame(t0).copyWith(skillLevels: {0: 400});
      expect(engine.achievementReward(s, a),
          closeTo(engine.incomePerSecond(s) * a.rewardIncomeSeconds, 1e-6));
      // With no income the floor applies.
      final broke = s.copyWith(skillLevels: const {});
      expect(engine.achievementReward(broke, a), a.rewardMin);
    });

    test('cannot claim what is not reached', () {
      final s = engine.newGame(t0);
      expect(() => engine.claimAchievement(s, 'contracts_100'),
          throwsA(isA<GameRuleException>()));
      expect(() => engine.claimAchievement(s, 'nope'),
          throwsA(isA<GameRuleException>()));
    });

    test('claiming works even before the tick noticed it', () {
      final s = collectOne(engine.newGame(t0));
      final claimed = engine.claimAchievement(s, 'first_contract');
      expect(claimed.isAchievementClaimed('first_contract'), isTrue);
    });

    test('progress shows current value against target', () {
      var s = engine.newGame(t0);
      final web = engine.achievementProgress(s, def('track_web'));
      expect(web.current, 1);
      expect(web.target, content.skillsInTrack('web').length);
      expect(web.fraction, closeTo(1 / web.target, 1e-9));

      final level = engine.achievementProgress(s, def('level_10'));
      expect(level.current, 1);
      s = s.copyWith(skillLevels: {0: 12});
      expect(engine.achievementProgress(s, def('level_10')).reached, isTrue);
      expect(engine.achievementProgress(s, def('level_10')).fraction, 1);
    });

    test('golden contracts and campaigns are counted', () {
      var s = collectOne(engine.newGame(t0), golden: true);
      expect(s.stats.goldenContractsCompleted, 1);
      s = engine.startCampaign(
          rich(s, 1e6), content.startingLocation.id, 'flyers', t0);
      final check = engine.checkAchievements(s);
      expect(check.unlocked.map((a) => a.id),
          containsAll(['golden_1', 'campaigns_1', 'first_contract']));
    });

    test('cities and tracks unlock achievements', () {
      var s = rich(engine.newGame(t0));
      s = engine.unlockLocation(s, content.locations[1].id, t0);
      s = s.copyWith(skillLevels: {
        for (final k in content.skillsInTrack('web')) k.id: 1,
      });
      final ids = engine.checkAchievements(s).unlocked.map((a) => a.id);
      expect(ids, containsAll(['cities_2', 'track_web', 'skills_3']));
    });
  });

  group('skill milestones', () {
    test('income doubles at each milestone level', () {
      final html = content.startingSkill;
      final at9 = engine.skillIncome(html, 9);
      final at10 = engine.skillIncome(html, 10);
      expect(at10, closeTo(at9 / 9 * 10 * 2, 1e-12));
      expect(engine.milestoneMultiplier(24), 2);
      expect(engine.milestoneMultiplier(25), 4);
      expect(engine.nextMilestone(1), 10);
      expect(engine.nextMilestone(25), 50);
      expect(engine.nextMilestone(1000), isNull);
    });
  });

  group('new upgrade lines', () {
    UpgradeLineDef lineFor(UpgradeEffect e) =>
        content.upgradeLines.firstWhere((l) => l.effect == e);

    /// One fresh offer in Berlin for [s], with a fixed random seed.
    Contract freshOffer(GameState s, {int seed = 3}) {
      final e = testEngine(seed: seed);
      final berlin = content.startingLocation.id;
      final cleared = s.copyWith(contracts: const [], lastTick: t0);
      final next = e.advance(cleared, t0.add(const Duration(seconds: 1))).state;
      return next.offersAt(berlin).single;
    }

    GameState levelUp(GameState s, UpgradeLineDef line, int times) {
      for (var i = 0; i < times; i++) {
        s = engine.upgradeItemLevel(s, line.id);
      }
      return s;
    }

    test('there are six lines, each with an effect of its own', () {
      expect(content.upgradeLines, hasLength(6));
      expect(content.upgradeLines.map((l) => l.effect).toSet(), hasLength(6));
    });

    test('internet makes offers arrive faster', () {
      final base = rich(engine.newGame(t0));
      final berlin = content.startingLocation.id;
      final before = engine.offerCooldownAt(base, berlin, t0);
      final s = levelUp(base, lineFor(UpgradeEffect.offerSpeed), 5);
      expect(engine.offerCooldownAt(s, berlin, t0), lessThan(before));
    });

    test('headphones make new jobs cost less energy', () {
      final base = rich(engine.newGame(t0));
      final s = levelUp(base, lineFor(UpgradeEffect.energySaver), 9);
      final plain = freshOffer(base);
      final saved = freshOffer(s);
      expect(saved.energy, lessThanOrEqualTo(plain.energy));
      expect(
          saved.energy,
          (plain.energy / engine.energySaverMultiplier(s))
              .round()
              .clamp(1, 99));
    });

    test('a portfolio makes clients pay more', () {
      final base = rich(engine.newGame(t0));
      final s = levelUp(base, lineFor(UpgradeEffect.clientPay), 5);
      final plain = freshOffer(base);
      final better = freshOffer(s);
      expect(
          better.pay,
          closeTo(
              plain.pay *
                  engine.clientPayMultiplier(s) /
                  engine.clientPayMultiplier(base),
              1e-6));
    });
  });

  group('daily reward', () {
    final day1 = DateTime(2026, 3, 2, 9);

    test('the first reward is day 1 and only once per day', () {
      var s = engine.newGame(day1);
      expect(engine.dailyRewardStatus(s, day1).available, isTrue);
      final before = s.balance;
      s = engine.claimDailyReward(s, day1);
      expect(s.balance, before + engine.dailyRewardCash(s, 1));
      expect(s.dailyStreak, 1);
      expect(
          engine
              .dailyRewardStatus(s, day1.add(const Duration(hours: 10)))
              .available,
          isFalse);
      expect(() => engine.claimDailyReward(s, day1),
          throwsA(isA<GameRuleException>()));
    });

    test('coming back the next day continues the streak', () {
      var s = engine.claimDailyReward(engine.newGame(day1), day1);
      final tomorrow = day1.add(const Duration(days: 1, hours: -8));
      final status = engine.dailyRewardStatus(s, tomorrow);
      expect(status.available, isTrue);
      expect(status.day, 2);
      s = engine.claimDailyReward(s, tomorrow);
      expect(s.dailyStreak, 2);
    });

    test('missing a day starts over at day 1', () {
      final s = engine.claimDailyReward(engine.newGame(day1), day1);
      final status =
          engine.dailyRewardStatus(s, day1.add(const Duration(days: 2)));
      expect(status.day, 1);
      expect(status.streak, 1);
    });

    test('the cycle wraps after 7 days; days 3 and 7 refill energy', () {
      var s = engine.newGame(day1);
      for (var d = 0; d < 7; d++) {
        final now = day1.add(Duration(days: d));
        final status = engine.dailyRewardStatus(s, now);
        expect(status.day, d + 1);
        s = engine.claimDailyReward(s.copyWith(energy: 0), now);
        expect(s.energy, engine.dailyRewardRefillsEnergy(d + 1) ? 100 : 0);
      }
      final day8 =
          engine.dailyRewardStatus(s, day1.add(const Duration(days: 7)));
      expect(day8.day, 1);
      expect(day8.streak, 8);
    });
  });

  group('rebrand', () {
    test('stars grow with the square root of run earnings', () {
      expect(engine.starsFor(9e5), 0);
      expect(engine.starsFor(1e6), 1);
      expect(engine.starsFor(1e8), 10);
      expect(engine.starsFor(1e10), 100);
    });

    test('you need at least one star to rebrand', () {
      final s = engine.newGame(t0);
      expect(engine.pendingStars(s), 0);
      expect(() => engine.rebrand(s, t0), throwsA(isA<GameRuleException>()));
    });

    test('passive income counts towards the run', () {
      final s = engine.newGame(t0);
      final later =
          engine.advance(s, t0.add(const Duration(seconds: 10))).state;
      expect(later.stats.runEarnings, greaterThan(0));
      expect(later.stats.runEarnings, later.stats.lifetimeEarnings);
    });

    test('rebranding resets the run but keeps stars, goals, chests, streak',
        () {
      var s = rich(engine.newGame(t0));
      s = engine.unlockLocation(s, content.locations[1].id, t0);
      s = engine.upgradeSkill(s, content.startingSkill.id);
      s = engine.claimDailyReward(s, t0);
      s = s.copyWith(
        stats: s.stats.copyWith(runEarnings: 4e8, lifetimeEarnings: 5e8),
        achievementsUnlocked: {'first_contract'},
        achievementsClaimed: {'first_contract'},
        chests: const [Chest(id: 999, type: 'wooden')],
      );
      final later = t0.add(const Duration(days: 3));
      final r = engine.rebrand(s, later);

      expect(r.reputation, 20);
      expect(r.stats.rebrands, 1);
      expect(r.stats.runEarnings, 0);
      expect(r.stats.lifetimeEarnings, 5e8);
      expect(r.balance, 0);
      expect(r.skillLevels, {content.startingSkill.id: 1});
      expect(r.locations.keys, [content.startingLocation.id]);
      expect(r.hiredCount, 0);
      expect(r.chests.single.id, 999);
      expect(r.achievementsClaimed, {'first_contract'});
      expect(r.dailyStreak, 1);
      expect(r.startedAt, s.startedAt);
      expect(r.offersAt(content.startingLocation.id), isNotEmpty);
    });

    test('each star adds 2% income', () {
      final s = engine.newGame(t0);
      final starred = s.copyWith(reputation: 10);
      expect(engine.incomePerSecond(starred),
          closeTo(engine.incomePerSecond(s) * 1.2, 1e-12));
    });
  });

  group('gift chests', () {
    Contract doneJob({bool golden = false}) => Contract(
          id: 7777,
          locationId: content.startingLocation.id,
          client: 'Test',
          message: '',
          pay: 100,
          duration: const Duration(minutes: 1),
          energy: 5,
          requiredPeople: 1,
          requirements: const [],
          golden: golden,
          status: ContractStatus.completed,
          acceptedAt: t0,
          assignees: const [kPlayerId],
          netPay: 100,
        );

    GameState withJob(GameState s, Contract c) =>
        s.copyWith(contracts: [...s.contracts, c]);

    test('VIP clients always leave a good chest', () {
      for (var seed = 0; seed < 20; seed++) {
        final e = testEngine(seed: seed);
        final s = e.collectContract(
            withJob(e.newGame(t0), doneJob(golden: true)), 7777);
        expect(s.chests, hasLength(1));
        expect(content.chestOrNull(s.chests.single.type)!.vipEligible, isTrue);
      }
    });

    test('regular jobs drop chests only sometimes', () {
      var drops = 0;
      for (var seed = 0; seed < 200; seed++) {
        final e = testEngine(seed: seed);
        final s = e.collectContract(withJob(e.newGame(t0), doneJob()), 7777);
        drops += s.chests.length;
      }
      expect(drops, inInclusiveRange(20, 70)); // ~20%
    });

    test('no chest when all slots are full', () {
      final full = List.generate(
          Balance.chestSlots, (i) => Chest(id: 100 + i, type: 'wooden'));
      final s = engine.collectContract(
          withJob(
              engine.newGame(t0).copyWith(chests: full), doneJob(golden: true)),
          7777);
      expect(s.chests, hasLength(Balance.chestSlots));
    });

    test('one chest unlocks at a time, then opens with rewards', () {
      var s = engine.newGame(t0).copyWith(chests: const [
        Chest(id: 1, type: 'golden'),
        Chest(id: 2, type: 'wooden'),
      ]);
      s = engine.startChestUnlock(s, 1, t0);
      expect(() => engine.startChestUnlock(s, 2, t0),
          throwsA(isA<GameRuleException>()));
      expect(
          () => engine.openChest(s, 1, t0), throwsA(isA<GameRuleException>()));

      final golden = content.chestOrNull('golden')!;
      final ready = t0.add(golden.unlockTime);
      expect(engine.isChestReady(s.chests.first, ready), isTrue);
      // A ready chest no longer blocks the next one.
      final both = engine.startChestUnlock(s, 2, ready);
      expect(both.chests.last.unlockStartedAt, ready);

      final levelsBefore = s.skillLevels.values.fold(0, (a, b) => a + b);
      final opened = engine.openChest(s.copyWith(energy: 0), 1, ready);
      expect(opened.cash, greaterThanOrEqualTo(golden.minCash));
      expect(opened.state.balance, s.balance + opened.cash);
      expect(opened.state.energy, golden.energy);
      expect(opened.state.skillLevels.values.fold(0, (a, b) => a + b),
          levelsBefore + golden.skillLevels);
      expect(opened.state.chests.map((c) => c.id), [2]);
      expect(opened.state.stats.chestsOpened, 1);
    });
  });

  group('AI assistant', () {
    Contract offer({int people = 1, int skillLevel = 1}) => Contract(
          id: 8888,
          locationId: content.startingLocation.id,
          client: 'Test',
          message: '',
          pay: 1000,
          duration: const Duration(minutes: 10),
          energy: 5,
          requiredPeople: people,
          requirements: [
            SkillRequirement(
                skillId: content.startingSkill.id, level: skillLevel)
          ],
        );

    GameState withOffer(GameState s, Contract c) =>
        s.copyWith(contracts: [...s.contracts.where((x) => x.id != c.id), c]);

    test('must be hired before it can work', () {
      final s = withOffer(engine.newGame(t0), offer());
      expect(engine.hasAi(s), isFalse);
      expect(() => engine.acceptOffer(s, 8888, const [kAiId], t0),
          throwsA(isA<GameRuleException>()));
    });

    test('hiring and upgrading cost more each level', () {
      var s = rich(engine.newGame(t0));
      final hire = engine.aiUpgradeCost(s)!;
      expect(hire, Balance.aiHireCost);
      s = engine.upgradeAi(s);
      expect(s.aiLevel, 1);
      expect(s.balance, 1e12 - hire);
      expect(engine.aiUpgradeCost(s)!, greaterThan(hire));
      expect(() => engine.upgradeAi(engine.newGame(t0)),
          throwsA(isA<GameRuleException>()));
    });

    test('knows a share of the player skills, at least level 1', () {
      var s = engine.upgradeAi(rich(engine.newGame(t0)));
      final html = content.startingSkill.id;
      s = s.copyWith(skillLevels: {html: 10});
      expect(engine.aiSkillLevel(s, html), 4); // 40% of 10
      s = s.copyWith(skillLevels: {html: 1});
      expect(engine.aiSkillLevel(s, html), 1);
      final unknown = content.skills.last.id;
      expect(engine.aiSkillLevel(s, unknown), 0);
      // Higher AI levels know more.
      s = s.copyWith(aiLevel: Balance.aiMaxLevel, skillLevels: {html: 10});
      expect(engine.aiSkillLevel(s, html), 10);
    });

    test('works without energy, takes its cut and has limited slots', () {
      var s = engine.upgradeAi(rich(engine.newGame(t0)));
      s = withOffer(s, offer()).copyWith(energy: 0);
      s = engine.acceptOffer(s, 8888, const [kAiId], t0);
      final job = s.contract(8888)!;
      expect(job.isActive, isTrue);
      expect(job.netPay, closeTo(1000 * (1 - Balance.aiCut / 100), 1e-9));
      expect(s.energy, 0);
      expect(engine.aiTasks(s), 1);
      expect(engine.aiAvailable(s), isFalse);

      // A second task needs the next slot level.
      final second = offer().copyWith();
      s = s.copyWith(contracts: [
        ...s.contracts,
        Contract(
          id: 8889,
          locationId: second.locationId,
          client: 'Test 2',
          message: '',
          pay: 1000,
          duration: const Duration(minutes: 10),
          energy: 5,
          requiredPeople: 1,
          requirements: second.requirements,
        ),
      ]);
      expect(() => engine.acceptOffer(s, 8889, const [kAiId], t0),
          throwsA(isA<GameRuleException>()));
      s = s.copyWith(aiLevel: Balance.aiTaskLevels[1]);
      expect(engine.aiTaskSlots(s), 2);
      s = engine.acceptOffer(s, 8889, const [kAiId], t0);
      expect(engine.aiTasks(s), 2);
    });

    test('teams up with the player on 2-person jobs in any city', () {
      var s = engine.upgradeAi(rich(engine.newGame(t0)));
      s = withOffer(s, offer(people: 2));
      s = engine.acceptOffer(s, 8888, const [kPlayerId, kAiId], t0);
      expect(s.contract(8888)!.assignees, containsAll([kPlayerId, kAiId]));
      expect(s.playerBusy, isTrue);
    });

    test('rebranding resets it', () {
      var s = engine.upgradeAi(rich(engine.newGame(t0)));
      s = s.copyWith(
          stats: s.stats.copyWith(runEarnings: Balance.rebrandEarningsPerStar));
      expect(engine.rebrand(s, t0).aiLevel, 0);
    });

    test('survives a save round trip', () {
      final s = engine.upgradeAi(rich(engine.newGame(t0)));
      expect(GameState.fromJson(s.toJson()).aiLevel, 1);
    });
  });

  group('team projects', () {
    LocationDef projectCity() =>
        content.locations.firstWhere((l) => l.hasProjects);

    test('Berlin has none, later cities do', () {
      expect(content.startingLocation.hasProjects, isFalse);
      expect(content.locations.where((l) => l.price > 0),
          everyElement(predicate<LocationDef>((l) => l.hasProjects)));
      expect(content.projectBriefs.length, greaterThanOrEqualTo(8));
    });

    test('a new project city starts with one project, more come later', () {
      final city = projectCity();
      var s = engine.unlockLocation(rich(engine.newGame(t0)), city.id, t0);
      s = engine.advance(s, t0).state;
      expect(s.projectsAt(city.id), hasLength(1));
      expect(s.offersAt(city.id), hasLength(city.maxOffers));
      s = engine.advance(s, t0.add(Balance.projectCooldown)).state;
      expect(s.projectsAt(city.id), hasLength(city.maxProjects));
    });

    test('projects need a team, take longer and pay more than jobs', () {
      final city = projectCity();
      var s = engine.unlockLocation(rich(engine.newGame(t0)), city.id, t0);
      s = engine.advance(s, t0.add(const Duration(hours: 1))).state;
      final project = s.projectsAt(city.id).first;
      final jobs = s.offersAt(city.id);
      expect(project.project, isTrue);
      expect(project.requiredPeople,
          greaterThanOrEqualTo(Balance.projectMinPeople));
      expect(project.golden, isFalse);
      expect(content.projectBriefs, contains(project.message));
      for (final job in jobs) {
        expect(project.duration, greaterThan(job.duration));
      }
      final avgJobPay =
          jobs.map((j) => j.pay).reduce((a, b) => a + b) / jobs.length;
      expect(project.pay, greaterThan(avgJobPay));
    });

    test('taking a project starts the project timer, not the job timer', () {
      final city = projectCity();
      var s = engine.upgradeAi(rich(engine.newGame(t0)));
      s = engine.unlockLocation(s, city.id, t0);
      s = engine.advance(s, t0).state;
      final project = s.projectsAt(city.id).single;
      // Make sure the pair can do it.
      s = s.copyWith(skillLevels: {
        for (final r in project.requirements) r.skillId: 500,
      }, energy: Balance.maxEnergy);
      final nextOfferAt = s.locations[city.id]!.nextOfferAt;
      s = engine.acceptOffer(
          s,
          project.id,
          [kPlayerId, kAiId, ...s.hiredAt(city.id).map((e) => e.id)]
              .take(project.requiredPeople)
              .toList(),
          t0);
      expect(s.contract(project.id)!.isActive, isTrue);
      expect(s.locations[city.id]!.nextOfferAt, nextOfferAt);
      expect(
          s.locations[city.id]!.nextProjectAt, t0.add(Balance.projectCooldown));
    });

    test('finished projects always leave a gift chest', () {
      final city = projectCity();
      final done = Contract(
        id: 9999,
        locationId: city.id,
        client: 'Test',
        message: 'Big build',
        pay: 100,
        duration: const Duration(hours: 1),
        energy: 5,
        requiredPeople: 2,
        requirements: const [],
        project: true,
        status: ContractStatus.completed,
        acceptedAt: t0,
        assignees: const [kPlayerId, kAiId],
        netPay: 100,
      );
      final s = engine.collectContract(
          engine.newGame(t0).copyWith(contracts: [done]), 9999);
      expect(s.chests, hasLength(1));
    });

    test('project flag and timer survive a save round trip', () {
      final city = projectCity();
      var s = engine.unlockLocation(rich(engine.newGame(t0)), city.id, t0);
      s = engine.advance(s, t0).state;
      final loaded = GameState.fromJson(s.toJson());
      expect(loaded.projectsAt(city.id), hasLength(1));
      expect(loaded.locations[city.id]!.nextProjectAt,
          s.locations[city.id]!.nextProjectAt);
    });
  });
}
