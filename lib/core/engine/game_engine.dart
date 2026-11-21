import 'dart:math';

import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';

/// Thrown when the player tries something the rules don't allow.
/// [message] is shown to the player.
class GameRuleException implements Exception {
  final String message;
  const GameRuleException(this.message);

  @override
  String toString() => 'GameRuleException: $message';
}

/// Result of advancing time.
class TickResult {
  final GameState state;

  /// Contracts that finished during this tick.
  final List<Contract> completed;

  /// Set when the player was away: how long, and what they earned.
  final Duration? awayFor;
  final double awayEarnings;

  /// Achievements reached during this tick (their rewards still need to be
  /// claimed with `GameEngine.claimAchievement`).
  final List<AchievementDef> newAchievements;

  const TickResult(
    this.state, {
    this.completed = const [],
    this.awayFor,
    this.awayEarnings = 0,
    this.newAchievements = const [],
  });
}

/// Result of [GameEngine.checkAchievements].
class AchievementCheck {
  final GameState state;

  /// Achievements that became unlocked in this check.
  final List<AchievementDef> unlocked;

  const AchievementCheck(this.state, [this.unlocked = const []]);
}

/// How far the player is towards an achievement.
class AchievementProgress {
  final double current;
  final double target;

  const AchievementProgress(this.current, this.target);

  /// 0 to 1, for progress bars.
  double get fraction => target <= 0 ? 1 : (current / target).clamp(0.0, 1.0);
  bool get reached => current >= target;
}

/// Combined effect of the marketing campaigns running in a location.
class CampaignEffects {
  final int extraOffers;
  final double offerCooldownMultiplier;
  final double payMultiplier;
  final double goldenChanceBonus;

  const CampaignEffects({
    this.extraOffers = 0,
    this.offerCooldownMultiplier = 1,
    this.payMultiplier = 1,
    this.goldenChanceBonus = 0,
  });

  static const none = CampaignEffects();
}

/// All game rules. Pure Dart, no Flutter: every method takes a state and
/// returns a new one, so the whole economy can be unit-tested.
class GameEngine {
  final GameContent content;
  final Random _random;

  GameEngine(this.content, {Random? random}) : _random = random ?? Random();

  // ===========================================================================
  // New game
  // ===========================================================================

  GameState newGame(DateTime now) {
    final start = content.startingLocation;
    final state = GameState(
      balance: 0,
      energy: Balance.maxEnergy,
      lastTick: now,
      startedAt: now,
      nextId: 1,
      skillLevels: Map.unmodifiable({content.startingSkill.id: 1}),
      upgrades: Map.unmodifiable({
        for (final line in content.upgradeLines)
          line.id: const UpgradeProgress(itemIndex: 0, level: 1)
      }),
      locations: Map.unmodifiable({start.id: _freshLocation(start, now)}),
      contracts: const [],
      employees: const [],
      stats: const GameStats(),
    );
    return _refill(state, now);
  }

  // ===========================================================================
  // Economy queries
  // ===========================================================================

  /// Passive income of one skill at [level], before upgrade bonuses.
  double skillIncome(SkillDef skill, int level) {
    final decay = pow(Balance.skillIncomeDecay, skill.rank);
    return skill.price * skill.rate / 100 / decay * level;
  }

  double baseIncomePerSecond(GameState s) {
    var total = 0.0;
    s.skillLevels.forEach((id, level) {
      final skill = content.skillOrNull(id);
      if (skill != null) total += skillIncome(skill, level);
    });
    return total;
  }

  double incomePerSecond(GameState s) =>
      baseIncomePerSecond(s) *
      (1 + upgradeBonus(s, UpgradeEffect.income) / 100);

  double energyRegenPerSecond(GameState s) =>
      Balance.energyRegenPerSecond *
      (1 + upgradeBonus(s, UpgradeEffect.energyRegen) / 100);

  /// New offers take `base duration / this`. 1 = no speed-up.
  double contractSpeedMultiplier(GameState s) =>
      1 + upgradeBonus(s, UpgradeEffect.contractSpeed) / 100;

  double wagesPerSecond(GameState s) => s.employees
      .where((e) => e.isHired)
      .fold(0.0, (sum, e) => sum + e.wagePerHour / 3600);

  /// Cost to raise [skill] from [level] to `level + 1`.
  double skillUpgradeCost(SkillDef skill, int level) {
    final growth = Balance.skillCostGrowthBase +
        skill.levelPriceRate * Balance.skillCostGrowthPerRate;
    return skill.price * pow(growth, level - 1);
  }

  bool isTrackOpen(GameState s, TrackDef track) =>
      s.skillLevels.length >= track.unlockAtSkills;

  /// First skill of [track] the player hasn't learned, or null if done.
  SkillDef? nextSkillInTrack(GameState s, TrackDef track) {
    for (final skill in content.skillsInTrack(track.id)) {
      if (!s.isSkillUnlocked(skill.id)) return skill;
    }
    return null;
  }

  /// The next skill of every open track: what the player can work towards.
  List<SkillDef> nextSkills(GameState s) => [
        for (final track in content.tracks)
          if (isTrackOpen(s, track))
            if (nextSkillInTrack(s, track) case final skill?) skill,
      ];

  /// Why [skill] can't be unlocked right now (ignoring money), or null.
  String? skillUnlockBlocker(GameState s, SkillDef skill) {
    if (s.isSkillUnlocked(skill.id)) return 'Already learned';
    final track = content.track(skill.track);
    if (!isTrackOpen(s, track)) {
      final missing = track.unlockAtSkills - s.skillLevels.length;
      return 'Learn $missing more skill${missing == 1 ? '' : 's'} '
          'to open ${track.name}';
    }
    final previous = content.previousSkill(skill.id);
    if (previous != null && !s.isSkillUnlocked(previous.id)) {
      return "Learn '${previous.name}' first";
    }
    if (previous != null &&
        s.skillLevel(previous.id) < skill.unlockOnPreviousLevel) {
      return "Requires '${previous.name}' at level ${skill.unlockOnPreviousLevel}";
    }
    return null;
  }

  // ---- Upgrades -------------------------------------------------------------

  /// Progress in [line]. Lines added after the save was made start at the
  /// first item, level 1.
  UpgradeProgress upgradeProgress(GameState s, UpgradeLineDef line) =>
      s.upgrades[line.id] ?? _firstUpgrade;

  static const _firstUpgrade = UpgradeProgress(itemIndex: 0, level: 1);

  UpgradeItemDef currentItem(GameState s, UpgradeLineDef line) =>
      line.items[upgradeProgress(s, line).itemIndex];

  UpgradeItemDef? nextItem(GameState s, UpgradeLineDef line) {
    final i = upgradeProgress(s, line).itemIndex + 1;
    return i < line.items.length ? line.items[i] : null;
  }

  /// Highest level the current item of [line] can reach.
  int maxItemLevel(GameState s, UpgradeLineDef line) =>
      nextItem(s, line)?.unlockOnPreviousLevel ??
      Balance.lastUpgradeItemMaxLevel;

  double upgradeLevelCost(UpgradeItemDef item, int level) {
    final growth = 1 + item.levelPriceRate * Balance.upgradeCostGrowthPerRate;
    return item.price * pow(growth, level - 1);
  }

  /// Total bonus in percent from all upgrade lines with [effect].
  double upgradeBonus(GameState s, UpgradeEffect effect) {
    var bonus = 0.0;
    for (final line in content.upgradeLines) {
      if (line.effect != effect) continue;
      final progress = s.upgrades[line.id];
      if (progress == null) continue;
      for (var i = 0; i < progress.itemIndex; i++) {
        // Items the player moved past count at the level needed to move on.
        bonus += line.items[i].rate * line.items[i + 1].unlockOnPreviousLevel;
      }
      bonus += line.items[progress.itemIndex].rate * progress.level;
    }
    return bonus;
  }

  // ---- Locations and employees ----------------------------------------------

  double employeeSlotCost(LocationDef location, int currentSlots) =>
      location.employeeSlotPrice *
      pow(location.employeeSlotPriceRate, currentSlots);

  /// Whether [assignees] together have every skill the contract needs.
  bool teamCovers(GameState s, Contract contract, Iterable<int> assignees) {
    for (final req in contract.requirements) {
      final covered =
          assignees.any((id) => _levelOf(s, id, req.skillId) >= req.level);
      if (!covered) return false;
    }
    return true;
  }

  /// Best level any of [assignees] has in [skillId].
  int bestLevel(GameState s, Iterable<int> assignees, int skillId) =>
      assignees.fold(0, (best, id) => max(best, _levelOf(s, id, skillId)));

  int _levelOf(GameState s, int personId, int skillId) {
    if (personId == kPlayerId) return s.skillLevel(skillId);
    return s.employee(personId)?.levelOf(skillId) ?? 0;
  }

  // ---- Marketing campaigns --------------------------------------------------

  double campaignCost(GameState s, CampaignDef campaign) =>
      max(campaign.minCost, incomePerSecond(s) * campaign.costIncomeSeconds);

  /// Campaigns running in [locationId] at [now].
  List<ActiveCampaign> activeCampaigns(
          GameState s, int locationId, DateTime now) =>
      s.campaigns
          .where((c) => c.locationId == locationId && c.isRunning(now))
          .toList(growable: false);

  /// The running campaign [campaignId] in [locationId], or null.
  ActiveCampaign? activeCampaign(
      GameState s, int locationId, String campaignId, DateTime now) {
    for (final c in activeCampaigns(s, locationId, now)) {
      if (c.campaignId == campaignId) return c;
    }
    return null;
  }

  /// Why [campaign] can't be started in [locationId] right now (ignoring
  /// money), or null.
  String? campaignBlocker(
      GameState s, int locationId, CampaignDef campaign, DateTime now) {
    final location = _location(locationId);
    if (!s.isLocationUnlocked(locationId)) {
      return 'Unlock ${location.city} first';
    }
    if (activeCampaign(s, locationId, campaign.id, now) != null) {
      return '${campaign.name} is already running in ${location.city}';
    }
    return null;
  }

  /// All running campaigns in [locationId] combined.
  CampaignEffects campaignEffects(GameState s, int locationId, DateTime now) {
    final running = activeCampaigns(s, locationId, now);
    if (running.isEmpty) return CampaignEffects.none;
    var extra = 0;
    var cooldown = 1.0, pay = 1.0, golden = 0.0;
    for (final active in running) {
      final c = content.campaignOrNull(active.campaignId);
      if (c == null) continue;
      extra += c.extraOffers;
      cooldown *= c.offerCooldownMultiplier;
      pay *= c.payMultiplier;
      golden += c.goldenChanceBonus;
    }
    return CampaignEffects(
      extraOffers: extra,
      offerCooldownMultiplier: cooldown,
      payMultiplier: pay,
      goldenChanceBonus: golden,
    );
  }

  /// How many offers [locationId] can show at once, campaigns included.
  int maxOffersAt(GameState s, int locationId, DateTime now) =>
      _location(locationId).maxOffers +
      campaignEffects(s, locationId, now).extraOffers;

  /// Wait between new offers in [locationId], campaigns included.
  Duration offerCooldownAt(GameState s, int locationId, DateTime now) =>
      Balance.offerCooldown *
      campaignEffects(s, locationId, now).offerCooldownMultiplier;

  // ---- Achievements ---------------------------------------------------------

  /// Current value versus target of [achievement]'s condition.
  AchievementProgress achievementProgress(
      GameState s, AchievementDef achievement) {
    final c = achievement.condition;
    final stats = s.stats;
    return switch (c.type) {
      AchievementConditionType.skillsLearned =>
        AchievementProgress(s.skillLevels.length.toDouble(), c.value),
      AchievementConditionType.contractsCompleted =>
        AchievementProgress(stats.contractsCompleted.toDouble(), c.value),
      AchievementConditionType.goldenContractsCompleted =>
        AchievementProgress(stats.goldenContractsCompleted.toDouble(), c.value),
      AchievementConditionType.lifetimeEarnings =>
        AchievementProgress(stats.lifetimeEarnings, c.value),
      AchievementConditionType.employeesHired =>
        AchievementProgress(stats.employeesHired.toDouble(), c.value),
      AchievementConditionType.citiesUnlocked =>
        AchievementProgress(s.locations.length.toDouble(), c.value),
      AchievementConditionType.campaignsRun =>
        AchievementProgress(stats.campaignsRun.toDouble(), c.value),
      AchievementConditionType.skillLevel => AchievementProgress(
          s.skillLevels.values.fold(0, max).toDouble(), c.value),
      AchievementConditionType.trackCompleted => () {
          final skills = content.skillsInTrack(c.trackId!);
          final learned = skills.where((k) => s.isSkillUnlocked(k.id)).length;
          return AchievementProgress(
              learned.toDouble(), skills.length.toDouble());
        }(),
    };
  }

  /// Cash paid when [achievement] is claimed now.
  double achievementReward(GameState s, AchievementDef achievement) => max(
      achievement.rewardMin,
      incomePerSecond(s) * achievement.rewardIncomeSeconds);

  /// Unlocks every achievement whose condition is met. `advance()` calls
  /// this; call it after actions too for instant feedback.
  AchievementCheck checkAchievements(GameState s) {
    final unlocked = [
      for (final a in content.achievements)
        if (!s.isAchievementUnlocked(a.id) && achievementProgress(s, a).reached)
          a,
    ];
    if (unlocked.isEmpty) return AchievementCheck(s);
    return AchievementCheck(
      s.copyWith(
        achievementsUnlocked: Set.unmodifiable(
            {...s.achievementsUnlocked, for (final a in unlocked) a.id}),
      ),
      List.unmodifiable(unlocked),
    );
  }

  // ===========================================================================
  // Time
  // ===========================================================================

  /// Moves the game forward to [now]: passive income, wages, energy,
  /// finished contracts, new offers and applicants. Handles long gaps
  /// (app closed) with the offline rules from [Balance].
  TickResult advance(GameState s, DateTime now) {
    s = _repair(s, now);
    final elapsed = now.difference(s.lastTick);
    if (elapsed <= Duration.zero) {
      // Clock moved backwards (or no time passed): just re-anchor.
      return TickResult(elapsed.isNegative ? s.copyWith(lastTick: now) : s);
    }

    final away = elapsed > Balance.offlineThreshold;
    final counted = elapsed > Balance.maxOfflineDuration
        ? Balance.maxOfflineDuration
        : elapsed;
    final seconds = counted.inMicroseconds / Duration.microsecondsPerSecond;

    final earned =
        incomePerSecond(s) * seconds * (away ? Balance.offlineIncomeFactor : 1);
    final wages = wagesPerSecond(s) * seconds;
    final energy = min(
      Balance.maxEnergy,
      s.energy + energyRegenPerSecond(s) * seconds,
    );

    // Finish contracts whose time is up and free their workers.
    final completed = <Contract>[];
    final contracts = <Contract>[];
    for (final c in s.contracts) {
      if (c.isActive && !c.finishesAt!.isAfter(now)) {
        final done = c.copyWith(status: ContractStatus.completed);
        completed.add(done);
        contracts.add(done);
      } else {
        contracts.add(c);
      }
    }
    final finishedIds = completed.map((c) => c.id).toSet();
    final employees = [
      for (final e in s.employees)
        if (finishedIds.contains(e.contractId))
          e.copyWith(contractId: () => null)
        else if (!e.isExpired(now)) // applicants who waited too long leave
          e
    ];

    var next = s.copyWith(
      balance: max(0, s.balance + earned - wages),
      energy: energy,
      lastTick: now,
      contracts: List.unmodifiable(contracts),
      employees: List.unmodifiable(employees),
      campaigns: s.campaigns.every((c) => c.isRunning(now))
          ? s.campaigns
          : List.unmodifiable(s.campaigns.where((c) => c.isRunning(now))),
      stats:
          s.stats.copyWith(lifetimeEarnings: s.stats.lifetimeEarnings + earned),
    );
    next = _refill(next, now);
    final check = checkAchievements(next);

    return TickResult(
      check.state,
      completed: completed,
      awayFor: away ? elapsed : null,
      awayEarnings: away ? earned : 0,
      newAchievements: check.unlocked,
    );
  }

  // ===========================================================================
  // Player actions. Each returns the new state or throws GameRuleException.
  // ===========================================================================

  GameState unlockSkill(GameState s, int skillId) {
    final skill = _skill(skillId);
    final blocker = skillUnlockBlocker(s, skill);
    if (blocker != null) throw GameRuleException(blocker);
    final paid = _pay(s, skill.price, 'unlock ${skill.name}');
    return paid.copyWith(
      skillLevels: Map.unmodifiable({...s.skillLevels, skillId: 1}),
    );
  }

  GameState upgradeSkill(GameState s, int skillId) {
    final skill = _skill(skillId);
    if (!s.isSkillUnlocked(skillId)) {
      throw GameRuleException('${skill.name} is not unlocked yet');
    }
    final level = s.skillLevel(skillId);
    final paid =
        _pay(s, skillUpgradeCost(skill, level), 'upgrade ${skill.name}');
    return paid.copyWith(
      skillLevels: Map.unmodifiable({...s.skillLevels, skillId: level + 1}),
    );
  }

  /// Raises the level of the current item in an upgrade line.
  GameState upgradeItemLevel(GameState s, int lineId) {
    final line = _line(lineId);
    final progress = upgradeProgress(s, line);
    final item = line.items[progress.itemIndex];
    if (progress.level >= maxItemLevel(s, line)) {
      throw GameRuleException(nextItem(s, line) == null
          ? '${item.name} is at max level'
          : 'Max level reached. Buy the next ${line.category}!');
    }
    final paid =
        _pay(s, upgradeLevelCost(item, progress.level), 'upgrade ${item.name}');
    return paid.copyWith(
      upgrades: Map.unmodifiable({
        ...s.upgrades,
        lineId: UpgradeProgress(
            itemIndex: progress.itemIndex, level: progress.level + 1),
      }),
    );
  }

  /// Replaces the current item of an upgrade line with the next one.
  GameState buyNextItem(GameState s, int lineId) {
    final line = _line(lineId);
    final progress = upgradeProgress(s, line);
    final next = nextItem(s, line);
    if (next == null) throw const GameRuleException('Nothing left to buy here');
    if (progress.level < next.unlockOnPreviousLevel) {
      throw GameRuleException(
          'Reach level ${next.unlockOnPreviousLevel} first');
    }
    final paid = _pay(s, next.price, 'buy ${next.name}');
    return paid.copyWith(
      upgrades: Map.unmodifiable({
        ...s.upgrades,
        lineId: UpgradeProgress(itemIndex: progress.itemIndex + 1, level: 1),
      }),
    );
  }

  GameState unlockLocation(GameState s, int locationId, DateTime now) {
    final location = _location(locationId);
    if (s.isLocationUnlocked(locationId)) {
      throw GameRuleException('${location.city} is already unlocked');
    }
    final paid = _pay(s, location.price, 'unlock ${location.city}');
    final next = paid.copyWith(
      locations: Map.unmodifiable({
        ...s.locations,
        locationId: _freshLocation(location, now),
      }),
    );
    return _refill(next, now);
  }

  GameState buyEmployeeSlot(GameState s, int locationId) {
    final location = _location(locationId);
    final progress = _locationProgress(s, locationId);
    if (progress.employeeSlots >= location.maxEmployees) {
      throw GameRuleException(
          '${location.city} has no more room for employees');
    }
    final paid = _pay(
        s, employeeSlotCost(location, progress.employeeSlots), 'buy a desk');
    return paid.copyWith(
      locations: Map.unmodifiable({
        ...s.locations,
        locationId:
            progress.copyWith(employeeSlots: progress.employeeSlots + 1),
      }),
    );
  }

  GameState hireCandidate(GameState s, int employeeId, DateTime now) {
    final candidate = _employee(s, employeeId);
    if (candidate.isHired) {
      throw GameRuleException('${candidate.name} already works for you');
    }
    final progress = _locationProgress(s, candidate.locationId);
    if (s.hiredAt(candidate.locationId).length >= progress.employeeSlots) {
      throw const GameRuleException('Buy another desk before hiring');
    }
    final paid = _pay(s, candidate.hireCost, 'hire ${candidate.name}');
    return paid.copyWith(
      employees: _replaceEmployee(
          s,
          candidate.copyWith(
              status: EmployeeStatus.hired, expiresAt: () => null)),
      locations: _bumpCandidateTimer(s, candidate.locationId, now),
      stats: paid.stats.copyWith(employeesHired: paid.stats.employeesHired + 1),
    );
  }

  GameState rejectCandidate(GameState s, int employeeId, DateTime now) {
    final candidate = _employee(s, employeeId);
    if (candidate.isHired) {
      throw GameRuleException('${candidate.name} already works for you');
    }
    return s.copyWith(
      employees:
          List.unmodifiable(s.employees.where((e) => e.id != employeeId)),
      locations: _bumpCandidateTimer(s, candidate.locationId, now),
    );
  }

  GameState fireEmployee(GameState s, int employeeId) {
    final employee = _employee(s, employeeId);
    if (!employee.isHired) {
      throw GameRuleException('${employee.name} does not work for you');
    }
    if (employee.isBusy) {
      throw GameRuleException('${employee.name} is working on a contract');
    }
    final paid = _pay(s, employee.fireCost, 'fire ${employee.name}');
    return paid.copyWith(
      employees:
          List.unmodifiable(s.employees.where((e) => e.id != employeeId)),
    );
  }

  GameState acceptOffer(
    GameState s,
    int contractId,
    List<int> assignees,
    DateTime now,
  ) {
    final offer = _contract(s, contractId);
    if (!offer.isOffer) {
      throw const GameRuleException('This offer is no longer available');
    }
    final team = assignees.toSet();
    if (team.length != offer.requiredPeople) {
      throw GameRuleException(
          'Pick ${offer.requiredPeople} ${offer.requiredPeople == 1 ? 'person' : 'people'}');
    }

    var cutPercent = 0;
    for (final id in team) {
      if (id == kPlayerId) {
        if (s.playerBusy) {
          throw const GameRuleException("You're already working on a contract");
        }
        continue;
      }
      final e = s.employee(id);
      if (e == null || !e.isHired || e.locationId != offer.locationId) {
        throw const GameRuleException('That person does not work here');
      }
      if (e.isBusy) throw GameRuleException('${e.name} is busy');
      cutPercent += e.cut;
    }
    if (!teamCovers(s, offer, team)) {
      throw const GameRuleException(
          "The team doesn't have the required skills");
    }
    final usesEnergy = team.contains(kPlayerId);
    if (usesEnergy && s.energy < offer.energy) {
      throw const GameRuleException(
          'Not enough energy. Rest a bit or let employees do it');
    }

    final accepted = offer.copyWith(
      status: ContractStatus.active,
      acceptedAt: now,
      assignees: List.unmodifiable(team),
      netPay: offer.pay * (1 - min(cutPercent, 100) / 100),
    );
    return s.copyWith(
      energy: usesEnergy ? s.energy - offer.energy : s.energy,
      contracts: _replaceContract(s, accepted),
      employees: List.unmodifiable([
        for (final e in s.employees)
          team.contains(e.id) ? e.copyWith(contractId: () => contractId) : e
      ]),
      locations: _bumpOfferTimer(s, offer.locationId, now),
    );
  }

  GameState rejectOffer(GameState s, int contractId, DateTime now) {
    final offer = _contract(s, contractId);
    if (!offer.isOffer) throw const GameRuleException('This is not an offer');
    return s.copyWith(
      contracts:
          List.unmodifiable(s.contracts.where((c) => c.id != contractId)),
      locations: _bumpOfferTimer(s, offer.locationId, now),
    );
  }

  /// Abandons an active contract. Energy is not refunded.
  GameState cancelContract(GameState s, int contractId) {
    final contract = _contract(s, contractId);
    if (!contract.isActive) {
      throw const GameRuleException('This contract is not running');
    }
    return s.copyWith(
      contracts:
          List.unmodifiable(s.contracts.where((c) => c.id != contractId)),
      employees: List.unmodifiable([
        for (final e in s.employees)
          e.contractId == contractId ? e.copyWith(contractId: () => null) : e
      ]),
    );
  }

  GameState collectContract(GameState s, int contractId) {
    final contract = _contract(s, contractId);
    if (!contract.isCompleted) {
      throw const GameRuleException('This contract is not finished yet');
    }
    return s.copyWith(
      balance: s.balance + contract.netPay,
      contracts:
          List.unmodifiable(s.contracts.where((c) => c.id != contractId)),
      stats: s.stats.copyWith(
        contractsCompleted: s.stats.contractsCompleted + 1,
        goldenContractsCompleted:
            s.stats.goldenContractsCompleted + (contract.golden ? 1 : 0),
        lifetimeEarnings: s.stats.lifetimeEarnings + contract.netPay,
      ),
    );
  }

  /// Starts [campaignId] in [locationId] until `now + duration`.
  GameState startCampaign(
    GameState s,
    int locationId,
    String campaignId,
    DateTime now,
  ) {
    final campaign = content.campaignOrNull(campaignId) ??
        (throw const GameRuleException('Unknown campaign'));
    final blocker = campaignBlocker(s, locationId, campaign, now);
    if (blocker != null) throw GameRuleException(blocker);
    final paid = _pay(
        s, campaignCost(s, campaign), 'run ${campaign.name.toLowerCase()}');

    var next = paid.copyWith(
      campaigns: List.unmodifiable([
        ...s.campaigns.where((c) => c.isRunning(now)),
        ActiveCampaign(
          locationId: locationId,
          campaignId: campaignId,
          endsAt: now.add(campaign.duration),
        ),
      ]),
      stats: paid.stats.copyWith(campaignsRun: paid.stats.campaignsRun + 1),
    );
    if (campaign.extraOffers > 0) {
      // The extra clients show up right away.
      final p = next.locations[locationId]!;
      final earliest = now.subtract(
          offerCooldownAt(next, locationId, now) * (campaign.extraOffers - 1));
      next = next.copyWith(
        locations: Map.unmodifiable({
          ...next.locations,
          locationId: p.copyWith(
              nextOfferAt:
                  p.nextOfferAt.isBefore(earliest) ? p.nextOfferAt : earliest),
        }),
      );
    }
    return _refill(next, now);
  }

  /// Pays the reward of a reached achievement, once.
  GameState claimAchievement(GameState s, String achievementId) {
    final achievement = content.achievementOrNull(achievementId) ??
        (throw const GameRuleException('Unknown achievement'));
    final checked = checkAchievements(s).state;
    if (checked.isAchievementClaimed(achievementId)) {
      throw const GameRuleException('Reward already claimed');
    }
    if (!checked.isAchievementUnlocked(achievementId)) {
      throw GameRuleException('Not there yet: ${achievement.description}');
    }
    return checked.copyWith(
      balance: checked.balance + achievementReward(checked, achievement),
      achievementsClaimed:
          Set.unmodifiable({...checked.achievementsClaimed, achievementId}),
    );
  }

  // ---- Debug helpers (settings menu in debug builds) ------------------------

  GameState debugAddMoney(GameState s, double amount) =>
      s.copyWith(balance: s.balance + amount);

  GameState debugRefillEnergy(GameState s) =>
      s.copyWith(energy: Balance.maxEnergy);

  // ===========================================================================
  // Generation of offers and applicants
  // ===========================================================================

  GameState _refill(GameState s, DateTime now) {
    var state = s;
    for (final entry in s.locations.entries) {
      final location = content.locationOrNull(entry.key);
      if (location == null) continue;
      var progress = entry.value;
      final contracts = [...state.contracts];
      final employees = [...state.employees];
      var nextId = state.nextId;

      final effects = campaignEffects(state, location.id, now);
      final maxOffers = location.maxOffers + effects.extraOffers;
      final cooldown = Balance.offerCooldown * effects.offerCooldownMultiplier;
      var offers = contracts
          .where((c) => c.locationId == location.id && c.isOffer)
          .length;
      while (offers < maxOffers && !progress.nextOfferAt.isAfter(now)) {
        contracts.add(_generateOffer(state, location, nextId++, effects));
        offers++;
        progress =
            progress.copyWith(nextOfferAt: progress.nextOfferAt.add(cooldown));
      }

      var candidates = employees
          .where((e) => e.locationId == location.id && !e.isHired)
          .length;
      while (candidates < location.maxEmployeeOffers &&
          !progress.nextCandidateAt.isAfter(now)) {
        employees
            .add(_generateCandidate(state, location, nextId++, employees, now));
        candidates++;
        progress = progress.copyWith(
            nextCandidateAt:
                progress.nextCandidateAt.add(Balance.candidateCooldown));
      }

      if (nextId != state.nextId) {
        state = state.copyWith(
          nextId: nextId,
          contracts: List.unmodifiable(contracts),
          employees: List.unmodifiable(employees),
          locations:
              Map.unmodifiable({...state.locations, location.id: progress}),
        );
      }
    }
    return state;
  }

  Contract _generateOffer(
    GameState s,
    LocationDef location,
    int id,
    CampaignEffects effects,
  ) {
    final unlocked = s.skillLevels.length;

    // Duration grows as the player progresses.
    final minSec = Balance.contractMinSecondsBase +
        Balance.contractMinSecondsPerSkill * (unlocked - 1);
    final maxSec = Balance.contractMaxSecondsBase +
        Balance.contractMaxSecondsPerSkill * (unlocked - 1);
    final baseSeconds = minSec + _random.nextInt(maxSec - minSec + 1);
    // Faster laptops shorten the work but not the pay.
    final duration = Duration(
        seconds: max(Balance.contractMinSeconds,
            (baseSeconds / contractSpeedMultiplier(s)).round()));

    // People: 1 until the player has staff here, then up to staff + 1.
    final staff = s.hiredAt(location.id).length;
    final people =
        1 + _random.nextInt(min(staff, Balance.maxRequiredPeople - 1) + 1);

    // Skill requirements: unlocked skills near the player's level. Without
    // staff here, every offer is doable by the player alone. With staff,
    // offers may ask a bit more than the player has, or the next locked skill,
    // which makes employees worth having.
    final pool = <SkillDef>[
      for (final skill in content.skills)
        if (s.isSkillUnlocked(skill.id)) skill,
    ];
    final upcoming = nextSkills(s);
    if (staff > 0 && upcoming.isNotEmpty && _random.nextDouble() < 0.25) {
      pool.add(_pick(upcoming));
    }
    pool.shuffle(_random);
    final count =
        1 + _random.nextInt(min(Balance.maxRequirements, pool.length));
    final requirements = [
      for (final skill in pool.take(count))
        SkillRequirement(
          skillId: skill.id,
          level: s.isSkillUnlocked(skill.id)
              ? _requiredLevel(s.skillLevel(skill.id), canStretch: staff > 0)
              : 1,
        ),
    ]..sort((a, b) => a.skillId - b.skillId);

    final golden =
        _random.nextDouble() < Balance.goldenChance + effects.goldenChanceBonus;
    final pay = (Balance.contractBasePay +
            incomePerSecond(s) * baseSeconds * Balance.contractIncomeMultiple) *
        effects.payMultiplier *
        location.rate *
        (1 + Balance.extraPersonPayBonus * (people - 1)) *
        (1 + Balance.perRequirementPayBonus * requirements.length) *
        (golden ? Balance.goldenMultiplier : 1);

    return Contract(
      id: id,
      locationId: location.id,
      client: _pick(location.names),
      message: _pick(location.messages),
      pay: pay,
      duration: duration,
      energy: Balance.contractEnergyMin +
          _random.nextInt(
              Balance.contractEnergyMax - Balance.contractEnergyMin + 1),
      requiredPeople: people,
      requirements: List.unmodifiable(requirements),
      golden: golden,
    );
  }

  Employee _generateCandidate(
    GameState s,
    LocationDef location,
    int id,
    List<Employee> existing,
    DateTime now,
  ) {
    final usedNames = existing
        .where((e) => e.locationId == location.id)
        .map((e) => e.name)
        .toSet();
    final freeNames =
        location.names.where((n) => !usedNames.contains(n)).toList();
    final name = _pick(freeNames.isEmpty ? location.names : freeNames);

    final pool = <SkillDef>[
      for (final skill in content.skills)
        if (s.isSkillUnlocked(skill.id)) skill,
    ];
    final upcoming = nextSkills(s);
    if (upcoming.isNotEmpty && _random.nextDouble() < 0.4) {
      pool.add(_pick(upcoming));
    }
    pool.shuffle(_random);
    final count = 1 + _random.nextInt(min(3, pool.length));
    final skills = <int, int>{
      for (final skill in pool.take(count))
        skill.id: s.isSkillUnlocked(skill.id)
            ? max(1, s.skillLevel(skill.id) - 2 + _random.nextInt(5))
            : 1 + _random.nextInt(3),
    };
    final power = skills.values.fold(0, (a, b) => a + b);

    final hireCost = max(Balance.minHireCost,
            incomePerSecond(s) * Balance.hireCostIncomeSeconds) *
        (0.8 + 0.4 * _random.nextDouble()) *
        (1 + 0.05 * power) *
        location.tier;

    return Employee(
      id: id,
      locationId: location.id,
      name: name,
      age: 18 + _random.nextInt(43),
      cut: Balance.employeeCutMin +
          _random.nextInt(Balance.employeeCutMax - Balance.employeeCutMin + 1),
      wagePerHour: hireCost * Balance.wagePerHourOfHireCost,
      hireCost: hireCost,
      fireCost: hireCost * Balance.fireCostOfHireCost,
      skills: Map.unmodifiable(skills),
      expiresAt: now.add(_candidateLifetime()),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  Duration _candidateLifetime() =>
      Balance.candidateLifetime *
      (1 + Balance.candidateLifetimeJitter * (2 * _random.nextDouble() - 1));

  /// Brings a state (e.g. from an older save) in line with the current
  /// content and rules. Returns [s] itself when nothing needs fixing.
  GameState _repair(GameState s, DateTime now) {
    final missingLines =
        content.upgradeLines.where((l) => !s.upgrades.containsKey(l.id));
    final undated = s.employees.any((e) => !e.isHired && e.expiresAt == null);
    if (missingLines.isEmpty && !undated) return s;
    return s.copyWith(
      upgrades: missingLines.isEmpty
          ? null
          : Map.unmodifiable({
              ...s.upgrades,
              for (final line in missingLines) line.id: _firstUpgrade,
            }),
      employees: !undated
          ? null
          : List.unmodifiable([
              for (final e in s.employees)
                !e.isHired && e.expiresAt == null
                    ? e.copyWith(expiresAt: () => now.add(_candidateLifetime()))
                    : e
            ]),
    );
  }

  /// A required level a few below the player's [level]; with [canStretch]
  /// it may also be one above.
  int _requiredLevel(int level, {required bool canStretch}) {
    final wanted = level - 3 + _random.nextInt(5);
    return max(1, canStretch ? wanted : min(level, wanted));
  }

  /// A newly opened location. Its timers are back-dated so it starts with a
  /// full set of offers and applicants.
  LocationProgress _freshLocation(LocationDef location, DateTime now) =>
      LocationProgress(
        employeeSlots: 0,
        nextOfferAt: now.subtract(Balance.offerCooldown * location.maxOffers),
        nextCandidateAt: now
            .subtract(Balance.candidateCooldown * location.maxEmployeeOffers),
      );

  GameState _pay(GameState s, double cost, String what) {
    if (s.balance < cost) {
      throw GameRuleException('Not enough money to $what');
    }
    return s.copyWith(balance: s.balance - cost);
  }

  SkillDef _skill(int id) =>
      content.skillOrNull(id) ?? (throw GameRuleException('Unknown skill $id'));

  UpgradeLineDef _line(int id) => content.upgradeLine(id);

  LocationDef _location(int id) =>
      content.locationOrNull(id) ??
      (throw GameRuleException('Unknown location $id'));

  LocationProgress _locationProgress(GameState s, int locationId) =>
      s.locations[locationId] ??
      (throw const GameRuleException('Unlock this location first'));

  Contract _contract(GameState s, int id) =>
      s.contract(id) ?? (throw const GameRuleException('Contract not found'));

  Employee _employee(GameState s, int id) =>
      s.employee(id) ?? (throw const GameRuleException('Person not found'));

  List<Contract> _replaceContract(GameState s, Contract updated) =>
      List.unmodifiable(
          [for (final c in s.contracts) c.id == updated.id ? updated : c]);

  List<Employee> _replaceEmployee(GameState s, Employee updated) =>
      List.unmodifiable(
          [for (final e in s.employees) e.id == updated.id ? updated : e]);

  /// After an offer is taken or turned down, wait before a new one shows up.
  Map<int, LocationProgress> _bumpOfferTimer(
      GameState s, int locationId, DateTime now) {
    final p = s.locations[locationId]!;
    final earliest = now.add(offerCooldownAt(s, locationId, now));
    return Map.unmodifiable({
      ...s.locations,
      locationId: p.copyWith(
          nextOfferAt:
              p.nextOfferAt.isAfter(earliest) ? p.nextOfferAt : earliest),
    });
  }

  Map<int, LocationProgress> _bumpCandidateTimer(
      GameState s, int locationId, DateTime now) {
    final p = s.locations[locationId]!;
    final earliest = now.add(Balance.candidateCooldown);
    return Map.unmodifiable({
      ...s.locations,
      locationId: p.copyWith(
          nextCandidateAt: p.nextCandidateAt.isAfter(earliest)
              ? p.nextCandidateAt
              : earliest),
    });
  }
}
