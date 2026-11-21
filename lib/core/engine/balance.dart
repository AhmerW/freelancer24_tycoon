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
  static const double skillIncomeDecay = 1.9;

  /// Level-up cost grows by `base + levelPriceRate * perRate` per level.
  static const double skillCostGrowthBase = 1.08;
  static const double skillCostGrowthPerRate = 0.03;

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
  static const Duration offerCooldown = Duration(seconds: 30);

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
}
