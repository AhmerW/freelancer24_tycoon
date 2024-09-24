import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:random_avatar/random_avatar.dart';

Alert employeeHiredAlert(Employee employee, Location location) =>
    Alert.fromWidget(
        "New employee!",
        Row(
          children: [
            RandomAvatar(
              employee.name,
              width: 40,
              height: 40,
              trBackground: true,
            ),
            Text(
              "Hired ${employee.name}",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        duration: AlertDuration.short);

Alert employeeFiredAlert(Employee employee, Location location) =>
    Alert.fromWidget(
        "Employee fired!",
        Row(
          children: [
            RandomAvatar(
              employee.name,
              width: 40,
              height: 40,
              trBackground: true,
            ),
            Text(
              "Fired ${employee.name}",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        duration: AlertDuration.short);
