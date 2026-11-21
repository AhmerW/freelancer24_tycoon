import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:random_avatar/random_avatar.dart';

/// A hired employee.
class EmployeeView extends StatelessWidget {
  final Employee employee;
  final VoidCallback onFire;

  const EmployeeView(this.employee, {super.key, required this.onFire});

  @override
  Widget build(BuildContext context) {
    final content = context.read<GameCubit>().content;
    final skills = employee.skills.entries
        .map((e) => '${content.skill(e.key).name} ${e.value}')
        .join(', ');
    return ListTile(
      leading: RandomAvatar(employee.name, width: 50, height: 50),
      title: Text(employee.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(employee.isBusy ? 'Working on a contract' : 'Available'),
          Text(skills),
          Text('${dollar(employee.wagePerHour)}/h · ${employee.cut}% cut'),
        ],
      ),
      trailing: TextButton(
        onPressed: employee.isBusy ? null : onFire,
        child: Text('Fire\n${dollar(employee.fireCost)}',
            textAlign: TextAlign.center),
      ),
    );
  }
}
