import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_offers_view.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employee_view.dart';

class EmployeesView extends StatefulWidget {
  final LocationDef location;
  final VoidCallback onBack;

  const EmployeesView(this.location, {super.key, required this.onBack});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  bool _showApplicants = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showApplicants
                ? EmployeeOffersView(widget.location,
                    key: const ValueKey('applicants'))
                : HiredEmployeesView(
                    widget.location,
                    key: const ValueKey('hired'),
                    onHire: () => setState(() => _showApplicants = true),
                  ),
          ),
        ),
        TextButton(
          onPressed: _showApplicants
              ? () => setState(() => _showApplicants = false)
              : widget.onBack,
          child: Text(_showApplicants ? 'Back to your team' : 'Go back'),
        ),
      ],
    );
  }
}

class HiredEmployeesView extends StatelessWidget {
  final LocationDef location;
  final VoidCallback onHire;

  const HiredEmployeesView(this.location, {super.key, required this.onHire});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final state = game.state;
    final hired = state.hiredAt(location.id);
    final slots = state.locations[location.id]!.employeeSlots;
    final slotCost = game.engine.employeeSlotCost(location, slots);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Employees ${hired.length} / $slots desks '
            '(room for ${location.maxEmployees})',
            textAlign: TextAlign.center,
          ),
        ),
        for (final e in hired)
          EmployeeView(e, onFire: () => game.fireEmployee(e.id)),
        for (var i = hired.length; i < slots; i++)
          ListTile(
            onTap: onHire,
            title: const Text('Empty desk'),
            subtitle: const Text('Tap to hire an employee'),
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
              child: const Icon(Icons.person_outline_outlined),
            ),
            trailing: Icon(Icons.add, color: Theme.of(context).primaryColor),
          ),
        if (slots < location.maxEmployees)
          ListTile(
            enabled: state.balance >= slotCost,
            onTap: () => game.buyEmployeeSlot(location.id),
            title: Text('Buy a desk for ${dollar(slotCost)}'),
            subtitle: const Text('Each employee needs a desk'),
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.4),
              child: const Icon(Icons.person_add_disabled_outlined),
            ),
            trailing: const Icon(Icons.lock_outline, color: Colors.red),
          ),
      ],
    );
  }
}
