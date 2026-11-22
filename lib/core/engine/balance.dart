/// Every tuning knob of the economy in one place.
///
/// The defaults were chosen with an economy simulation (see
/// `test/economy_simulation_test.dart`): a player with four 15-minute sessions
/// a day unlocks ~6 skills in the first session, the second city on day 1, and
/// the last skill after roughly two weeks.
abstract final class Balance {
  // ---- Skills --------------------------------------------------------------

  /// Each later skill earns this much less per dollar spent than the previous
  /// one. Higher = slower game.
  static const double skillIncomeDecay = 2.1;

  /// Level-up cost grows by `base + levelPriceRate * perRate` per level.
  static const double skillCostGrowthBase = 1.08;
  static const double skillCostGrowthPerRate = 0.03;

  /// Skill levels at which that skill's income doubles (milestones).
  static const List<int> skillMilestones = [10, 25, 50, 100, 150, 200, 300];
  static const double milestoneMultiplier = 2;

  // ---- Daily reward --------------------------------------------------------

  /// A 7-day cycle. Each day pays this many seconds of current income...
  static const List<double> dailyRewardIncomeSeconds = [
    120,
    240,
    360,
    600,
    900,
    1200,
    3600,
  ];

  /// ...but at least this much.
  static const List<double> dailyRewardMin = [25, 50, 100, 150, 250, 400, 1000];

  /// Days (1-7) that also refill energy.
  static const Set<int> dailyRewardEnergyDays = {3, 7};

  // ---- Rebrand (prestige) --------------------------------------------------

  /// Stars for a run: floor(sqrt(run earnings / this)).
  static const double rebrandEarningsPerStar = 1e6;

  /// Income bonus per reputation star (0.02 = +2%).
  static const double reputationBonusPerStar = 0.02;

  /// The game recommends rebranding once it gains at least this many stars
  /// and at least as many as the player already has (doubling them).
  static const int rebrandRecommendMinStars = 10;

  // ---- Gift chests ---------------------------------------------------------

  static const int chestSlots = 4;

  /// Chance that a regular job leaves a chest (VIP jobs always do).
  static const double chestDropChance = 0.2;

  // ---- Upgrades ------------------------------------------------------------

  /// Level-up cost of an upgrade item grows by `1 + levelPriceRate * this`.
  static const double upgradeCostGrowthPerRate = 0.1;

  /// Max level of the last item in an upgrade line.
  static const int lastUpgradeItemMaxLevel = 25;

  // ---- Energy --------------------------------------------------------------

  static const double maxEnergy = 100;

  /// Base regen: a full bar in one hour.
  static const double energyRegenPerSecond = maxEnergy / 3600;
  static const int contractEnergyMin = 5;
  static const int contractEnergyMax = 15;

  // ---- Offline progress ----------------------------------------------------

  /// A gap longer than this between ticks counts as "away".
  static const Duration offlineThreshold = Duration(seconds: 60);
  static const double offlineIncomeFactor = 0.5;
  static const Duration maxOfflineDuration = Duration(hours: 8);

  // ---- Contracts -----------------------------------------------------------

  static const double contractBasePay = 15;

  /// A contract pays this many times the passive income earned over its
  /// duration.
  static const double contractIncomeMultiple = 3;
  static const double goldenChance = 0.1;

  /// A VIP client waits this long before leaving.
  static const Duration vipOfferLifetime = Duration(minutes: 10);

  /// A VIP asks for one skill this many levels above the player's (1 to 3):
  /// almost there, so the player levels up (or brings a teammate) to take it.
  static const int vipStretchMin = 1;
  static const int vipStretchMax = 3;
  static const double goldenMultiplier = 3;
  static const double extraPersonPayBonus = 0.5;
  static const double perRequirementPayBonus = 0.1;
  static const int maxRequiredPeople = 3;
  static const int maxRequirements = 3;

  /// Offer duration in seconds = base + perSkill * (unlocked skills - 1).
  static const int contractMinSecondsBase = 20;
  static const int contractMinSecondsPerSkill = 10;
  static const int contractMaxSecondsBase = 60;
  static const int contractMaxSecondsPerSkill = 120;
  static const Duration offerCooldown = Duration(seconds: 75);

  /// Shortest a contract can get with contract-speed upgrades.
  static const int contractMinSeconds = 5;

  // ---- Employees -----------------------------------------------------------

  static const Duration candidateCooldown = Duration(seconds: 60);

  /// How long a job applicant waits before leaving, randomized by
  /// `1 ± candidateLifetimeJitter`. Hired employees never leave.
  static const Duration candidateLifetime = Duration(minutes: 20);
  static const double candidateLifetimeJitter = 0.25;

  /// Hire cost is worth this many seconds of current income (with a floor).
  static const double hireCostIncomeSeconds = 600;
  static const double minHireCost = 100;
  static const double wagePerHourOfHireCost = 0.05;
  static const double fireCostOfHireCost = 0.25;
  static const int employeeCutMin = 5;
  static const int employeeCutMax = 25;

  // ---- AI assistant ----------------------------------------------------------

  /// Price to hire the AI assistant (its level 1).
  static const double aiHireCost = 20000;

  /// Each AI level costs this much more than the one before.
  static const double aiUpgradeGrowth = 2;
  static const int aiMaxLevel = 25;

  /// The AI's skill levels are this share of the player's (level 1 and up).
  static const double aiSkillShareBase = 0.4;
  static const double aiSkillSharePerLevel = 0.025;

  /// AI levels at which it can work on one more task at the same time.
  static const List<int> aiTaskLevels = [1, 8, 16, 25];

  /// Percent of a contract's pay the AI costs to run (like an employee's cut).
  static const int aiCut = 30;

  // ---- Team projects -------------------------------------------------------

  /// A new project offer appears this long after one is taken or declined.
  static const Duration projectCooldown = Duration(minutes: 15);

  /// A project takes this many times as long as a regular job.
  static const int projectLengthMin = 4;
  static const int projectLengthMax = 7;
  static const Duration projectMinDuration = Duration(minutes: 10);
  static const Duration projectMaxDuration = Duration(hours: 8);

  /// A project pays this many seconds of income per second of work (jobs pay
  /// [contractIncomeMultiple]). Lower than jobs on purpose: projects keep
  /// earning while the player is away, so their rate must not beat the
  /// offline-income cap by much. In total, one project pays far more than a
  /// job.
  static const double projectIncomeMultiple = 1;
  static const int projectMinPeople = 2;
  static const int projectMaxPeople = 4;
  static const int projectEnergyMultiplier = 2;
}
