# Freelancer24 Tycoon

Offline idle/tycoon game (Flutter) about building a freelance career. Target:
young people curious about freelancing. Everything runs on the device: no
servers, no accounts; the save lives in a Hive box.

## Commands

```bash
flutter analyze                      # must report "No issues found!"
flutter test                         # unit tests + economy simulation
flutter test test/economy_simulation_test.dart   # prints the pacing table
flutter build ios --simulator --debug            # then launch Runner.app
python3 tool/build_skills.py         # regenerate assets/data/skills.json
python3 tool/build_sounds.py         # regenerate assets/sounds/*.wav
```

Run `dart format lib test` before committing.

## Architecture

- `lib/core/` is plain Dart with no Flutter imports, so it is fully unit-testable.
  - `content/`: static game data loaded from `assets/data/*.json` (tracks,
    skills, upgrade lines, locations, marketing campaigns, achievements).
    Read-only at runtime.
  - `state/game_state.dart`: the entire player progress as one immutable
    object, serialized to one versioned JSON save (`kSaveVersion`). A save
    format change requires bumping the version and adding a migration in
    `GameState.fromJson`.
  - `engine/game_engine.dart`: every rule. Actions take a state and return a
    new one or throw `GameRuleException` (its message is shown to the player).
    `advance()` moves time forward, including offline catch-up, applicant
    expiry, ending campaigns and unlocking achievements
    (`TickResult.newAchievements`). It also repairs older saves (missing
    upgrade lines, applicants without an expiry time).
  - `engine/balance.dart`: every tuning constant. Change numbers here, then
    check the simulation output.
- `lib/game/`: `GameCubit` (1s tick, autosave, lifecycle, notices) and
  `AlertCubit` (on-screen toasts).
- `lib/views/`: UI only. Views read `GameCubit` state and call its action
  methods. No game rules in widgets.
  - `game_ui/`: the game look. Use these instead of plain Material widgets:
    `GameButton` (3D, haptics, `shine:` when affordable), `StrokeText`
    (outlined titles/numbers), `GamePanel`, `IconBadge`, `GameProgressBar`,
    `CoinIcon`, `RollingNumber`, `Bouncy`, `GameTone` color sets,
    `GameFonts` (Lilita One display, Nunito body).
  - `FxLayer` (`Fx.of(context)`): `coinBurst`, `floatText`, `confetti`.
    Call it from a `Builder` context of the button that triggered the action,
    after the cubit action returned true.
  - `widgets/coach.dart`: first-run hints derived from game state (no save).
- Sound: `lib/game/sfx.dart` (`Sfx.instance.play(Sound.x)`). Buttons, coins,
  confetti and chime notices already play sounds. The WAVs in
  `assets/sounds/` are synthesized by `python3 tool/build_sounds.py`; tweak a
  recipe there and re-run rather than adding sampled audio.

## Content

- Skills are organized in career tracks (`tool/skills_source.json`: names,
  descriptions, icons). `tool/build_skills.py` derives prices, ranks and ids
  and writes `assets/data/skills.json`. Edit the source plus the script, never
  the generated file.
- Skill ids are saved in player saves: never renumber existing ids.
- Skill icons are either a PNG in `assets/icons/skills/` or a Material icon
  name listed in `skillMaterialIcons` (`lib/views/skills/skills_widgets.dart`).
- `upgrades.json`: one line per category (coffee, chair, laptop); icons live in
  `assets/icons/upgrades/<category>/` (each folder must be listed in
  `pubspec.yaml`), or a Material icon name (see `skillMaterialIcons`).
  Effects: `income`, `energyRegen`, `contractSpeed`, `offerSpeed`,
  `energySaver`, `clientPay`.
- Skill milestones (`Balance.skillMilestones`) double a skill's income at
  levels 10, 25, 50, ...; daily reward amounts live in `Balance` too.
- `locations.json`: cities, sorted by price in game. `icon` is a PNG in
  `assets/icons/locations/` or `""` (the UI shows a generic icon).
- `marketing.json`: campaigns run per city for `durationSeconds`; cost is
  `costIncomeSeconds` of current income (at least `minCost`); `effects` stack
  across different campaigns. Campaign ids are saved in player saves.
- `achievements.json`: `condition` `{type, value}` (types in
  `AchievementConditionType`; `trackCompleted` takes a track id as value);
  reward is `rewardIncomeSeconds` of income at claim time, at least
  `rewardMin`. Achievement ids are saved in player saves: never rename.

## Conventions

- Any economy change must keep `test/economy_simulation_test.dart` green.
  Update its bounds only when the pacing change is intentional.
- New rules get engine tests in `test/game_engine_test.dart`.
- Avoid real brand or company names in game text.
- Verify UI changes in the iOS simulator (iPhone 17 Pro) before committing.
