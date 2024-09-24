import 'package:freelancer24_tycoon/data/models/locations/contract.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';

class Location {
  final int id;
  final String city;
  final String country;
  final String abbreviation;
  final int price;
  final int tier;
  final double rate;
  final double widthMultiplier; // for world map positioning
  final double heightMultiplier; // for world map positioning
  final List<String> names;
  final List<String> messages;
  final String message;
  final String icon;
  final int maxOffers;
  final int maxEmployees;
  final int employeeSlotPrice;
  final int maxEmployeeOffers;
  final double employeeSlotPriceRate;

  int level = 1;
  int employeeSlots = 0;
  bool locked = false;

  bool get unlocked => !locked;

  Location({
    required this.id,
    required this.city,
    required this.country,
    required this.price,
    required this.tier,
    required this.widthMultiplier,
    required this.heightMultiplier,
    required this.names,
    required this.abbreviation,
    required this.rate,
    required this.messages,
    required this.message,
    required this.icon,
    required this.maxOffers,
    required this.maxEmployees,
    required this.employeeSlotPrice,
    required this.maxEmployeeOffers,
    required this.employeeSlotPriceRate,
    this.level = 1,
    this.employeeSlots = 0,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      city: json['city'],
      country: json['country'],
      price: json['price'],
      tier: json['tier'],
      widthMultiplier: json['widthMultiplier'],
      heightMultiplier: json['heightMultiplier'],
      names: List<String>.from(json['names'] as List),
      abbreviation: json['abbreviation'],
      rate: json['rate'],
      message: json['message'],
      level: json["level"] ?? 1,
      icon: json["icon"],
      maxOffers: json["maxOffers"],
      maxEmployees: json["maxEmployees"],
      employeeSlotPrice: json["employeeSlotPrice"],
      messages: List<String>.from(json['messages'] as List),
      employeeSlots: json['employeeSlots'] ?? 0,
      maxEmployeeOffers: json['maxEmployeeOffers'],
      employeeSlotPriceRate: json['employeeSlotPriceRate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city,
      'country': country,
      'price': price,
      'tier': tier,
      'widthMultiplier': widthMultiplier,
      'heightMultiplier': heightMultiplier,
      'names': names,
      'abbreviation': abbreviation,
      'rate': rate,
      'level': level,
      'messages': messages,
      'message': message,
      'icon': icon,
      'maxOffers': maxOffers,
      'maxEmployees': maxEmployees,
      'employeeSlotPrice': employeeSlotPrice,
      'employeeSlots': employeeSlots,
      'maxEmployeeOffers': maxEmployeeOffers,
      'employeeSlotPriceRate': employeeSlotPriceRate,
    };
  }

  Location updateWith(LocationData data) {
    level = data.level;
    employeeSlots = data.employeeSlots;
    return this;
  }
}

// in the future convert this to a generic hive type adapter with generic fields "stringField1" etc,
// useful also for other repositories instead of dealing with jsonEncode / decodes

class LocationData {
  int level;
  int employeeSlots;

  LocationData({
    required this.level,
    required this.employeeSlots,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      level: json['level'],
      employeeSlots: json['employeeSlots'],
    );
  }
  factory LocationData.fromLocation(Location loc) {
    return LocationData(
      level: loc.level,
      employeeSlots: loc.employeeSlots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'employeeSlots': employeeSlots,
    };
  }
}

class ActiveLocationState {
  Location location;
  List<Employee> employees;
  List<Contract> contracts;

  ActiveLocationState({
    required this.location,
    required this.employees,
    required this.contracts,
  });
}
