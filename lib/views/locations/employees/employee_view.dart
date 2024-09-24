import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/data/models/office/employee.dart';
import 'package:random_avatar/random_avatar.dart';

class EmployeeView extends StatefulWidget {
  final Employee employee;
  final Function() fireCallback;
  const EmployeeView(
    this.employee, {
    super.key,
    required this.fireCallback,
  });

  @override
  State<EmployeeView> createState() => _EmployeeViewState();
}

class _EmployeeViewState extends State<EmployeeView> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.employee.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Assigned: ${widget.employee.assignedTo}"),
          TextButton(
            onPressed: widget.fireCallback,
            child: const Text("Fire"),
          )
        ],
      ),
      leading: RandomAvatar(widget.employee.name, width: 50, height: 50),
    );
  }
}
