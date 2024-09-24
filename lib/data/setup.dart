import 'package:freelancer24_tycoon/data/database/json_database.dart';
import 'package:get_it/get_it.dart';
import "package:hive_flutter/hive_flutter.dart";

Future<void> setup() async {
  await Hive.initFlutter();
  await Hive.openBox("user");
  await Hive.openBox("skills");
  await Hive.openBox("locations");
  await Hive.openBox("contracts");
  await Hive.openBox("upgrades");
  await Hive.openBox("employees");

  JsonDatabase db = await JsonDatabase.create();
  GetIt.I.registerSingleton<JsonDatabase>(db);
}
