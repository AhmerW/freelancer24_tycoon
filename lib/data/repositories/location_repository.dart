import 'dart:convert';

import 'package:freelancer24_tycoon/data/database/json_database.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

List<int> defaultLocations = [0];

class LocationRepository {
  Map<int, LocationData> mappedLocations = {};

  List<Location> getAllLocations() {
    return GetIt.I<JsonDatabase>().getAllLocations();
  }

  List<Location> getLocations() {
    List<Location> locations = [];
    var locMap = getLocationLevelMap();
    var allLocations = getAllLocations();
    for (Location loc in allLocations) {
      // loop thrugh all locations and check if user has that location unlocked
      if (locMap.containsKey(loc.id)) {
        locations.add(loc.updateWith(locMap[loc.id]!));
        loc.locked = false;
      } else {
        loc.locked = true;
      }
    }
    return locations;
  }

  Map<int, LocationData> getLocationLevelMap() {
    // All unlocked locations mapped to their level
    if (mappedLocations.isNotEmpty) {
      return mappedLocations;
    }
    var locBox = Hive.box("locations");

    var boxes = locBox.toMap();
    if (boxes.isEmpty) {
      // Empty box, first time playing, no locations
      for (int loc in defaultLocations) {
        locBox.put(
          loc,
          jsonEncode(LocationData(level: 1, employeeSlots: 0).toJson()),
        ); // skill : (level, slots)
      }
      mappedLocations = {
        for (var e in defaultLocations)
          e: LocationData(level: 1, employeeSlots: 0)
      };
      return mappedLocations;
    } else {}

    // Not first time, map all unlocked locations to levels
    for (var key in boxes.keys) {
      print("key: ${boxes[key]}");
      mappedLocations[key] = LocationData.fromJson(jsonDecode(boxes[key]));
    }

    return mappedLocations;
  }

  void resetLocations() {
    var locBox = Hive.box("locations");
    locBox.clear();
    mappedLocations = {};
  }

  void update(Location loc) {
    var locBox = Hive.box("locations");
    LocationData data = LocationData.fromLocation(loc);
    locBox.put(loc.id, jsonEncode(data.toJson()));
    mappedLocations[loc.id] = data;
  }

  void upgradeLocation(Location loc) {
    loc.level++;
    update(loc);
  }

  void unlockLocation(Location loc) {
    loc.locked = false;
    update(loc);
  }

  void unlockEmployeeSlot(Location loc) {
    loc.employeeSlots++;
    update(loc);
  }

  void resetAllLocationData() {
    resetLocations();
  }
}
