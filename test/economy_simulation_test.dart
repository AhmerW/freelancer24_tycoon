import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

import 'helpers.dart';

/// Plays the real engine with a simple bot to check pacing.
///
/// Schedule: 4 sessions a day, 15 minutes each, 5-second ticks while playing,
/// one big offline jump in between (exactly what the app does on resume).
/// The bot collects pay, takes solo contracts, claims achievements, runs
/// online ads in the city it works in when they cost under 10% of its cash,
/// unlocks cities when it has 1.5x their price, and spends the rest on the
/// best income-per-dollar buy.
///
/// Run with `flutter test test/economy_simulation_test.dart` to see the
/// milestone table when tuning `Balance`.
void main() {
  test('progression pacing stays in the intended range', () {
    final engine = testEngine(seed: 7);
    final content = engine.content;
    final milestones = <String, Duration>{};
    var s = engine.newGame(t0);

    void mark(String name, DateTime now) =>
        milestones.putIfAbsent(name, () => now.difference(t0));

    const sessionsPerDay = 4;
    const session = Duration(minutes: 15);
    const tick = Duration(seconds: 5);
    const days = 60;

    for (var day = 0; day < days; day++) {
      for (var i = 0; i < sessionsPerDay; i++) {
        final start =
            t0.add(Duration(days: day, hours: i * 24 ~/ sessionsPerDay));
        // Offline catch-up, then play.
        s = _advance(engine, s, start, mark);
        for (var t = start; t.isBefore(start.add(session)); t = t.add(tick)) {
          s = _advance(engine, s, t, mark);
          s = _playTurn(engine, s, t, mark);
        }
      }
    }

    // Print the table so tuning changes are easy to compare.
    final table = (milestones.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)))
        .map((e) => '${e.key.padRight(28)} ${_fmt(e.value)}')
        .join('\n');
    // ignore: avoid_print
    print('Economy milestones (bot, 4x15min/day):\n$table\n'
        'Final income: ${dollar(engine.incomePerSecond(s) * 3600)}/h, '
        'skills ${s.skillLevels.length}/${content.skills.length}, '
        'achievements ${s.achievementsClaimed.length}/'
        '${content.achievements.length}, '
        'campaigns ${s.stats.campaignsRun}, '
        'contracts ${s.stats.contractsCompleted}, '
        'top skill level ${s.skillLevels.values.reduce(max)}, '
        'lifetime ${dollar(s.stats.lifetimeEarnings)}');

    Duration at(String key) => milestones[key] ?? const Duration(days: 999);
    Duration learned(int n) => at('learned $n skills');
    final all = content.skills.length;

    // The first session should feel rewarding...
    expect(learned(2), lessThan(const Duration(minutes: 5)));
    expect(learned(5), lessThan(const Duration(minutes: 20)));
    // ...the second city should come on day 1 or 2...
    expect(at('city ${content.locations[1].city}'),
        lessThan(const Duration(days: 2)));
    // ...and the game should last weeks, not days.
    expect(learned(all), greaterThan(const Duration(days: 14)));
    expect(learned(all), lessThan(const Duration(days: days)));
  });
}

GameState _advance(
  GameEngine engine,
  GameState s,
  DateTime now,
  void Function(String, DateTime) mark,
) {
  final result = engine.advance(s, now);
  for (final a in result.newAchievements) {
    mark('achievement ${a.title}', now);
  }
  return result.state;
}

GameState _playTurn(
  GameEngine engine,
  GameState s,
  DateTime now,
  void Function(String, DateTime) mark,
) {
  final content = engine.content;

  if (engine.dailyRewardStatus(s, now).available) {
    s = engine.claimDailyReward(s, now);
  }

  for (final c in s.contracts.where((c) => c.isCompleted).toList()) {
    s = engine.collectContract(s, c.id);
  }
  for (final id in s.achievementsUnlocked.difference(s.achievementsClaimed)) {
    s = engine.claimAchievement(s, id);
  }

  // Ads where the bot works: the city of its last contract.
  final city = s.contracts.isEmpty
      ? content.startingLocation.id
      : s.contracts.last.locationId;
  for (final campaign in content.campaigns.where((c) => c.id == 'online')) {
    if (engine.campaignBlocker(s, city, campaign, now) == null &&
        engine.campaignCost(s, campaign) < s.balance * 0.1) {
      s = engine.startCampaign(s, city, campaign.id, now);
    }
  }

  if (!s.playerBusy) {
    for (final offer in s.contracts.where((c) => c.isOffer)) {
      if (offer.requiredPeople == 1 &&
          s.energy >= offer.energy &&
          engine.teamCovers(s, offer, const [kPlayerId])) {
        s = engine.acceptOffer(s, offer.id, const [kPlayerId], now);
        break;
      }
    }
  }

  for (final loc in content.locations) {
    if (!s.isLocationUnlocked(loc.id) && s.balance >= loc.price * 1.5) {
      s = engine.unlockLocation(s, loc.id, now);
      mark('city ${loc.city}', now);
    }
  }

  // Greedy: buy the option with the best cost per income gained.
  for (var guard = 0; guard < 200; guard++) {
    final base = engine.incomePerSecond(s);
    GameState? best;
    String? bestName;
    var bestRatio = double.infinity;

    void consider(String name, double cost, GameState Function() apply) {
      if (cost > s.balance) return;
      final next = apply();
      final gain = engine.incomePerSecond(next) - base;
      // Energy upgrades don't add income; buy them when they are cheap.
      final ratio = gain > 0
          ? cost / gain
          : (cost < s.balance * 0.05 ? 0.0 : double.infinity);
      if (ratio < bestRatio) {
        bestRatio = ratio;
        best = next;
        bestName = name;
      }
    }

    for (final skill in content.skills) {
      if (s.isSkillUnlocked(skill.id)) {
        consider('', engine.skillUpgradeCost(skill, s.skillLevel(skill.id)),
            () => engine.upgradeSkill(s, skill.id));
      } else if (engine.skillUnlockBlocker(s, skill) == null) {
        consider('skill ${skill.name}', skill.price,
            () => engine.unlockSkill(s, skill.id));
      }
    }
    for (final UpgradeLineDef line in content.upgradeLines) {
      final p = s.upgrades[line.id]!;
      if (p.level < engine.maxItemLevel(s, line)) {
        consider(
            '',
            engine.upgradeLevelCost(engine.currentItem(s, line), p.level),
            () => engine.upgradeItemLevel(s, line.id));
      } else if (engine.nextItem(s, line) case final next?) {
        consider('${line.category} ${next.name}', next.price,
            () => engine.buyNextItem(s, line.id));
      }
    }

    if (best == null) break;
    s = best!;
    if (bestName!.isNotEmpty) mark(bestName!, now);
    if (bestName!.startsWith('skill ')) {
      mark('learned ${s.skillLevels.length} skills', now);
    }
  }
  return s;
}

String _fmt(Duration d) {
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${(d.inMinutes / 60).toStringAsFixed(1)}h';
  return 'day ${d.inDays + 1}';
}
