/// The complete, serializable player progress.
///
/// Everything is immutable: the engine returns a new [GameState] for every
/// change. That makes UI updates reliable (a new object is always "different")
/// and keeps the save format in one place.
library;

/// Bump this when the save format changes, and add a migration in
/// `GameState.fromJson`.
const int kSaveVersion = 1;

/// Id used for the player ("You") when assigning people to a contract.
/// Employee ids start at 1.
const int kPlayerId = 0;

class SkillRequirement {
  final int skillId;
  final int level;

  const SkillRequirement({required this.skillId, required this.level});

  factory SkillRequirement.fromJson(Map<String, dynamic> json) =>
      SkillRequirement(
        skillId: json['skillId'] as int,
        level: json['level'] as int,
      );

  Map<String, dynamic> toJson() => {'skillId': skillId, 'level': level};

  @override
  bool operator ==(Object other) =>
      other is SkillRequirement &&
      other.skillId == skillId &&
      other.level == level;

  @override
  int get hashCode => Object.hash(skillId, level);
}

enum ContractStatus { offer, active, completed }

class Contract {
  final int id;
  final int locationId;
  final String client;
  final String message;

  /// Pay before employee cuts.
  final double pay;
  final Duration duration;

  /// Energy the player spends if they work on the contract themselves.
  final int energy;
  final int requiredPeople;
  final List<SkillRequirement> requirements;
  final bool golden;
  final ContractStatus status;
  final DateTime? acceptedAt;
  final List<int> assignees;

  /// Pay after employee cuts. Fixed when the contract is accepted.
  final double netPay;

  const Contract({
    required this.id,
    required this.locationId,
    required this.client,
    required this.message,
    required this.pay,
    required this.duration,
    required this.energy,
    required this.requiredPeople,
    required this.requirements,
    this.golden = false,
    this.status = ContractStatus.offer,
    this.acceptedAt,
    this.assignees = const [],
    this.netPay = 0,
  });

  bool get isOffer => status == ContractStatus.offer;
  bool get isActive => status == ContractStatus.active;
  bool get isCompleted => status == ContractStatus.completed;
  bool get includesPlayer => assignees.contains(kPlayerId);

  DateTime? get finishesAt => acceptedAt?.add(duration);

  /// Time left until the contract finishes; zero once it is done.
  Duration remaining(DateTime now) {
    final end = finishesAt;
    if (end == null) return duration;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Progress from 0 to 1.
  double progress(DateTime now) {
    if (isCompleted) return 1;
    if (acceptedAt == null || duration.inMilliseconds == 0) return 0;
    final done =
        now.difference(acceptedAt!).inMilliseconds / duration.inMilliseconds;
    return done.clamp(0.0, 1.0);
  }

  Contract copyWith({
    ContractStatus? status,
    DateTime? acceptedAt,
    List<int>? assignees,
    double? netPay,
  }) =>
      Contract(
        id: id,
        locationId: locationId,
        client: client,
        message: message,
        pay: pay,
        duration: duration,
        energy: energy,
        requiredPeople: requiredPeople,
        requirements: requirements,
        golden: golden,
        status: status ?? this.status,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        assignees: assignees ?? this.assignees,
        netPay: netPay ?? this.netPay,
      );

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: json['id'] as int,
        locationId: json['locationId'] as int,
        client: json['client'] as String,
        message: json['message'] as String,
        pay: (json['pay'] as num).toDouble(),
        duration: Duration(seconds: json['durationSeconds'] as int),
        energy: json['energy'] as int,
        requiredPeople: json['requiredPeople'] as int,
        requirements: (json['requirements'] as List)
            .map((e) => SkillRequirement.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        golden: json['golden'] as bool? ?? false,
        status: ContractStatus.values.byName(json['status'] as String),
        acceptedAt: json['acceptedAt'] == null
            ? null
            : DateTime.parse(json['acceptedAt'] as String),
        assignees: List<int>.unmodifiable(json['assignees'] as List? ?? []),
        netPay: (json['netPay'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'locationId': locationId,
        'client': client,
        'message': message,
        'pay': pay,
        'durationSeconds': duration.inSeconds,
        'energy': energy,
        'requiredPeople': requiredPeople,
        'requirements': requirements.map((e) => e.toJson()).toList(),
        'golden': golden,
        'status': status.name,
        'acceptedAt': acceptedAt?.toIso8601String(),
        'assignees': assignees,
        'netPay': netPay,
      };
}

enum EmployeeStatus { candidate, hired }

class Employee {
  final int id;
  final int locationId;
  final String name;
  final int age;

  /// Percent of a contract's pay the employee keeps.
  final int cut;
  final double wagePerHour;
  final double hireCost;
  final double fireCost;

  /// skillId -> level
  final Map<int, int> skills;
  final EmployeeStatus status;

  /// The contract the employee is working on, if any.
  final int? contractId;

  /// When a job applicant gives up and leaves. Null for hired employees
  /// (they never expire) and for applicants from saves made before applicants
  /// could expire (the engine fills it in on the next tick).
  final DateTime? expiresAt;

  const Employee({
    required this.id,
    required this.locationId,
    required this.name,
    required this.age,
    required this.cut,
    required this.wagePerHour,
    required this.hireCost,
    required this.fireCost,
    required this.skills,
    this.status = EmployeeStatus.candidate,
    this.contractId,
    this.expiresAt,
  });

  bool get isHired => status == EmployeeStatus.hired;

  /// Whether this applicant has left by [now]. Hired employees never expire.
  bool isExpired(DateTime now) =>
      !isHired && expiresAt != null && !expiresAt!.isAfter(now);

  /// Time until this applicant leaves, or null if they don't expire.
  Duration? expiresIn(DateTime now) {
    if (isHired || expiresAt == null) return null;
    final left = expiresAt!.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool get isBusy => contractId != null;
  int levelOf(int skillId) => skills[skillId] ?? 0;

  Employee copyWith({
    EmployeeStatus? status,
    int? Function()? contractId,
    DateTime? Function()? expiresAt,
  }) =>
      Employee(
        id: id,
        locationId: locationId,
        name: name,
        age: age,
        cut: cut,
        wagePerHour: wagePerHour,
        hireCost: hireCost,
        fireCost: fireCost,
        skills: skills,
        status: status ?? this.status,
        contractId: contractId != null ? contractId() : this.contractId,
        expiresAt: expiresAt != null ? expiresAt() : this.expiresAt,
      );

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int,
        locationId: json['locationId'] as int,
        name: json['name'] as String,
        age: json['age'] as int,
        cut: json['cut'] as int,
        wagePerHour: (json['wagePerHour'] as num).toDouble(),
        hireCost: (json['hireCost'] as num).toDouble(),
        fireCost: (json['fireCost'] as num).toDouble(),
        skills: _intMap(json['skills']),
        status: EmployeeStatus.values.byName(json['status'] as String),
        contractId: json['contractId'] as int?,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'locationId': locationId,
        'name': name,
        'age': age,
        'cut': cut,
        'wagePerHour': wagePerHour,
        'hireCost': hireCost,
        'fireCost': fireCost,
        'skills': _stringKeys(skills),
        'status': status.name,
        'contractId': contractId,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

/// Which item of an upgrade line the player owns, and its level.
class UpgradeProgress {
  final int itemIndex;
  final int level;

  const UpgradeProgress({required this.itemIndex, required this.level});

  factory UpgradeProgress.fromJson(Map<String, dynamic> json) =>
      UpgradeProgress(
        itemIndex: json['itemIndex'] as int,
        level: json['level'] as int,
      );

  Map<String, dynamic> toJson() => {'itemIndex': itemIndex, 'level': level};

  @override
  bool operator ==(Object other) =>
      other is UpgradeProgress &&
      other.itemIndex == itemIndex &&
      other.level == level;

  @override
  int get hashCode => Object.hash(itemIndex, level);
}

/// Progress in an unlocked location.
class LocationProgress {
  final int employeeSlots;

  /// When the next contract offer may appear.
  final DateTime nextOfferAt;

  /// When the next job applicant may appear.
  final DateTime nextCandidateAt;

  const LocationProgress({
    required this.employeeSlots,
    required this.nextOfferAt,
    required this.nextCandidateAt,
  });

  LocationProgress copyWith({
    int? employeeSlots,
    DateTime? nextOfferAt,
    DateTime? nextCandidateAt,
  }) =>
      LocationProgress(
        employeeSlots: employeeSlots ?? this.employeeSlots,
        nextOfferAt: nextOfferAt ?? this.nextOfferAt,
        nextCandidateAt: nextCandidateAt ?? this.nextCandidateAt,
      );

  factory LocationProgress.fromJson(Map<String, dynamic> json) =>
      LocationProgress(
        employeeSlots: json['employeeSlots'] as int,
        nextOfferAt: DateTime.parse(json['nextOfferAt'] as String),
        nextCandidateAt: DateTime.parse(json['nextCandidateAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'employeeSlots': employeeSlots,
        'nextOfferAt': nextOfferAt.toIso8601String(),
        'nextCandidateAt': nextCandidateAt.toIso8601String(),
      };
}

/// A marketing campaign running in a location until [endsAt].
class ActiveCampaign {
  final int locationId;

  /// Id of a `CampaignDef`.
  final String campaignId;
  final DateTime endsAt;

  const ActiveCampaign({
    required this.locationId,
    required this.campaignId,
    required this.endsAt,
  });

  bool isRunning(DateTime now) => endsAt.isAfter(now);

  Duration remaining(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  factory ActiveCampaign.fromJson(Map<String, dynamic> json) => ActiveCampaign(
        locationId: json['locationId'] as int,
        campaignId: json['campaignId'] as String,
        endsAt: DateTime.parse(json['endsAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'campaignId': campaignId,
        'endsAt': endsAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is ActiveCampaign &&
      other.locationId == locationId &&
      other.campaignId == campaignId &&
      other.endsAt == endsAt;

  @override
  int get hashCode => Object.hash(locationId, campaignId, endsAt);
}

class GameStats {
  final int contractsCompleted;
  final double lifetimeEarnings;
  final int employeesHired;

  /// Collected golden (VIP) contracts.
  final int goldenContractsCompleted;

  /// Marketing campaigns started.
  final int campaignsRun;

  const GameStats({
    this.contractsCompleted = 0,
    this.lifetimeEarnings = 0,
    this.employeesHired = 0,
    this.goldenContractsCompleted = 0,
    this.campaignsRun = 0,
  });

  GameStats copyWith({
    int? contractsCompleted,
    double? lifetimeEarnings,
    int? employeesHired,
    int? goldenContractsCompleted,
    int? campaignsRun,
  }) =>
      GameStats(
        contractsCompleted: contractsCompleted ?? this.contractsCompleted,
        lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
        employeesHired: employeesHired ?? this.employeesHired,
        goldenContractsCompleted:
            goldenContractsCompleted ?? this.goldenContractsCompleted,
        campaignsRun: campaignsRun ?? this.campaignsRun,
      );

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        contractsCompleted: json['contractsCompleted'] as int? ?? 0,
        lifetimeEarnings: (json['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
        employeesHired: json['employeesHired'] as int? ?? 0,
        goldenContractsCompleted: json['goldenContractsCompleted'] as int? ?? 0,
        campaignsRun: json['campaignsRun'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'contractsCompleted': contractsCompleted,
        'lifetimeEarnings': lifetimeEarnings,
        'employeesHired': employeesHired,
        'goldenContractsCompleted': goldenContractsCompleted,
        'campaignsRun': campaignsRun,
      };
}

class GameState {
  final double balance;
  final double energy;

  /// Last time the engine advanced the game. Used for offline progress.
  final DateTime lastTick;
  final DateTime startedAt;

  /// Next id for contracts and employees.
  final int nextId;

  /// Unlocked skills: skillId -> level.
  final Map<int, int> skillLevels;

  /// Upgrade line id -> progress.
  final Map<int, UpgradeProgress> upgrades;

  /// Unlocked locations: locationId -> progress.
  final Map<int, LocationProgress> locations;

  /// Offers, active and completed contracts in every location.
  final List<Contract> contracts;

  /// Job applicants and hired employees in every location.
  final List<Employee> employees;
  final GameStats stats;

  /// Marketing campaigns, running or just ended (`advance()` removes ended
  /// ones). Use `GameEngine.activeCampaigns` to list the running ones.
  final List<ActiveCampaign> campaigns;

  /// Ids of achievements the player has reached.
  final Set<String> achievementsUnlocked;

  /// Ids of achievements whose reward was paid out. Always a subset of
  /// [achievementsUnlocked].
  final Set<String> achievementsClaimed;

  const GameState({
    required this.balance,
    required this.energy,
    required this.lastTick,
    required this.startedAt,
    required this.nextId,
    required this.skillLevels,
    required this.upgrades,
    required this.locations,
    required this.contracts,
    required this.employees,
    required this.stats,
    this.campaigns = const [],
    this.achievementsUnlocked = const {},
    this.achievementsClaimed = const {},
  });

  // ---- Queries -------------------------------------------------------------

  bool isSkillUnlocked(int skillId) => skillLevels.containsKey(skillId);
  int skillLevel(int skillId) => skillLevels[skillId] ?? 0;
  bool isLocationUnlocked(int locationId) => locations.containsKey(locationId);

  Contract? contract(int id) {
    for (final c in contracts) {
      if (c.id == id) return c;
    }
    return null;
  }

  Employee? employee(int id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Contract> offersAt(int locationId) => contracts
      .where((c) => c.locationId == locationId && c.isOffer)
      .toList(growable: false);

  /// Active and completed (not yet collected) contracts.
  List<Contract> runningContractsAt(int locationId) => contracts
      .where((c) => c.locationId == locationId && !c.isOffer)
      .toList(growable: false);

  List<Employee> hiredAt(int locationId) => employees
      .where((e) => e.locationId == locationId && e.isHired)
      .toList(growable: false);

  List<Employee> candidatesAt(int locationId) => employees
      .where((e) => e.locationId == locationId && !e.isHired)
      .toList(growable: false);

  int get hiredCount => employees.where((e) => e.isHired).length;

  /// True while the player is working on a contract.
  bool get playerBusy => contracts.any((c) => c.isActive && c.includesPlayer);

  int get contractsReadyToCollect =>
      contracts.where((c) => c.isCompleted).length;

  bool isAchievementUnlocked(String id) => achievementsUnlocked.contains(id);
  bool isAchievementClaimed(String id) => achievementsClaimed.contains(id);

  /// Reached achievements whose reward is waiting to be claimed.
  int get achievementsToClaim =>
      achievementsUnlocked.difference(achievementsClaimed).length;

  GameState copyWith({
    double? balance,
    double? energy,
    DateTime? lastTick,
    DateTime? startedAt,
    int? nextId,
    Map<int, int>? skillLevels,
    Map<int, UpgradeProgress>? upgrades,
    Map<int, LocationProgress>? locations,
    List<Contract>? contracts,
    List<Employee>? employees,
    GameStats? stats,
    List<ActiveCampaign>? campaigns,
    Set<String>? achievementsUnlocked,
    Set<String>? achievementsClaimed,
  }) =>
      GameState(
        balance: balance ?? this.balance,
        energy: energy ?? this.energy,
        lastTick: lastTick ?? this.lastTick,
        startedAt: startedAt ?? this.startedAt,
        nextId: nextId ?? this.nextId,
        skillLevels: skillLevels ?? this.skillLevels,
        upgrades: upgrades ?? this.upgrades,
        locations: locations ?? this.locations,
        contracts: contracts ?? this.contracts,
        employees: employees ?? this.employees,
        stats: stats ?? this.stats,
        campaigns: campaigns ?? this.campaigns,
        achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
        achievementsClaimed: achievementsClaimed ?? this.achievementsClaimed,
      );

  // ---- Serialization -------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'version': kSaveVersion,
        'balance': balance,
        'energy': energy,
        'lastTick': lastTick.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'nextId': nextId,
        'skillLevels': _stringKeys(skillLevels),
        'upgrades': {
          for (final e in upgrades.entries) '${e.key}': e.value.toJson()
        },
        'locations': {
          for (final e in locations.entries) '${e.key}': e.value.toJson()
        },
        'contracts': contracts.map((c) => c.toJson()).toList(),
        'employees': employees.map((e) => e.toJson()).toList(),
        'stats': stats.toJson(),
        'campaigns': campaigns.map((c) => c.toJson()).toList(),
        'achievementsUnlocked': achievementsUnlocked.toList()..sort(),
        'achievementsClaimed': achievementsClaimed.toList()..sort(),
      };

  /// Throws [FormatException] if the save is unreadable or from a newer
  /// version of the game.
  factory GameState.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! int || version > kSaveVersion) {
      throw FormatException('Unsupported save version: $version');
    }
    // Future migrations go here: `if (version < 2) json = _migrateV1(json);`
    // Keys added within version 1 (campaigns, achievements, applicant expiry,
    // new stats) are optional and default to empty/zero when missing.
    try {
      return GameState(
        balance: (json['balance'] as num).toDouble(),
        energy: (json['energy'] as num).toDouble(),
        lastTick: DateTime.parse(json['lastTick'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
        nextId: json['nextId'] as int,
        skillLevels: Map.unmodifiable(_intMap(json['skillLevels'])),
        upgrades: Map.unmodifiable({
          for (final e in (json['upgrades'] as Map).entries)
            int.parse(e.key as String):
                UpgradeProgress.fromJson(e.value as Map<String, dynamic>)
        }),
        locations: Map.unmodifiable({
          for (final e in (json['locations'] as Map).entries)
            int.parse(e.key as String):
                LocationProgress.fromJson(e.value as Map<String, dynamic>)
        }),
        contracts: List.unmodifiable((json['contracts'] as List)
            .map((e) => Contract.fromJson(e as Map<String, dynamic>))),
        employees: List.unmodifiable((json['employees'] as List)
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))),
        stats: GameStats.fromJson(json['stats'] as Map<String, dynamic>),
        campaigns: List.unmodifiable((json['campaigns'] as List? ?? const [])
            .map((e) => ActiveCampaign.fromJson(e as Map<String, dynamic>))),
        achievementsUnlocked: Set.unmodifiable(
            (json['achievementsUnlocked'] as List? ?? const []).cast<String>()),
        achievementsClaimed: Set.unmodifiable(
            (json['achievementsClaimed'] as List? ?? const []).cast<String>()),
      );
    } on TypeError catch (e) {
      throw FormatException('Corrupt save: $e');
    }
  }
}

Map<int, int> _intMap(Object? raw) => {
      for (final e in (raw as Map).entries)
        int.parse(e.key as String): e.value as int
    };

Map<String, int> _stringKeys(Map<int, int> map) =>
    {for (final e in map.entries) '${e.key}': e.value};
