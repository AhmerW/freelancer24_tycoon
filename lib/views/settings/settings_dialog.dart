import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/blocs/locations/location_bloc.dart';
import 'package:freelancer24_tycoon/blocs/skills/skill_bloc.dart';
import 'package:freelancer24_tycoon/blocs/upgrades/upgrade_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert.dart';
import 'package:freelancer24_tycoon/data/repositories/functions.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        UserBloc userBloc = BlocProvider.of<UserBloc>(context);
        SkillsBloc skillsBloc = BlocProvider.of<SkillsBloc>(context);
        UpgradeBloc upgradeBloc = BlocProvider.of<UpgradeBloc>(context);
        LocationBloc locationBloc = BlocProvider.of<LocationBloc>(context);
        AlertBloc alertBloc = BlocProvider.of<AlertBloc>(context);
        if (state is LoadedUserState) {
          return SizedBox(
            width: 500,
            height: 500,
            child: AlertDialog(
              title: const Text("Settings"),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        userBloc.add(IncreaseUserBalanceEvent(10000));
                      },
                      child: Text("+${r'$'}${formatMoney(10000.0)}")),
                  ElevatedButton(
                      onPressed: () {
                        userBloc.add(IncreaseUserBalanceEvent(100000));
                      },
                      child: Text("+${r'$'}${formatMoney(100000.0)}")),
                  ElevatedButton(
                      onPressed: () {
                        userBloc.add(SetUserBalaceEvent(0));
                      },
                      child: const Text("+${r'$'}0 (Reset)")),
                  ElevatedButton(
                    onPressed: () {
                      skillsBloc.add(ResetSkillsEvent());
                    },
                    child: const Text("Reset skills"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      upgradeBloc.add(ResetAllUpgradesEvent());
                    },
                    child: const Text("Reset all upgrades"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      locationBloc.add(ResetLocationsEvent());
                    },
                    child: const Text("Reset all locations"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      userBloc.add(SetUserEnergyEvent(100));
                    },
                    child: const Text("Reset energy"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      alertBloc.add(PushAlertEvent(Alert(UniqueKey().hashCode,
                          title: "test",
                          message: "test message",
                          priority: AlertPriority.high)));
                    },
                    child: const Text("High alert"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
