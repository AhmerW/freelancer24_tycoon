import 'dart:convert';

import 'package:freelancer24_tycoon/core/state/game_state.dart';

/// Where the game is saved. The app uses Hive; tests use [MemorySaveStore].
abstract class SaveStore {
  /// Raw JSON of the saved game, or null if there is none.
  Future<String?> read();
  Future<void> write(String json);

  /// Keeps an unreadable save around instead of overwriting it, so it can be
  /// recovered by hand if needed.
  Future<void> backupCorrupt(String json);
  Future<void> clear();
}

class MemorySaveStore implements SaveStore {
  String? data;
  final List<String> corrupt = [];

  MemorySaveStore([this.data]);

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String json) async => data = json;

  @override
  Future<void> backupCorrupt(String json) async => corrupt.add(json);

  @override
  Future<void> clear() async => data = null;
}

/// Loads and saves [GameState] through a [SaveStore].
class SaveRepository {
  final SaveStore store;

  SaveRepository(this.store);

  /// The saved game, or null if there is none or it couldn't be read
  /// (an unreadable save is backed up first).
  Future<GameState?> load() async {
    final raw = await store.read();
    if (raw == null) return null;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await store.backupCorrupt(raw);
      return null;
    }
  }

  Future<void> save(GameState state) => store.write(jsonEncode(state.toJson()));

  Future<void> clear() => store.clear();
}
