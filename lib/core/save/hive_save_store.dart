import 'package:freelancer24_tycoon/core/save/save_store.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores the save as one JSON string in a Hive box on the device.
class HiveSaveStore implements SaveStore {
  static const _boxName = 'save';
  static const _key = 'game';

  /// Boxes used by the 2024 prototype. They are deleted on first launch.
  static const _legacyBoxes = [
    'user',
    'skills',
    'locations',
    'contracts',
    'upgrades',
    'employees',
  ];

  final Box<String> _box;

  HiveSaveStore._(this._box);

  static Future<HiveSaveStore> open() async {
    await Hive.initFlutter();
    for (final name in _legacyBoxes) {
      if (await Hive.boxExists(name)) await Hive.deleteBoxFromDisk(name);
    }
    return HiveSaveStore._(await Hive.openBox<String>(_boxName));
  }

  @override
  Future<String?> read() async => _box.get(_key);

  @override
  Future<void> write(String json) => _box.put(_key, json);

  @override
  Future<void> backupCorrupt(String json) =>
      _box.put('corrupt_${DateTime.now().millisecondsSinceEpoch}', json);

  @override
  Future<void> clear() => _box.delete(_key);
}
