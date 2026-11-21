import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/world/team/employee_offers_view.dart';
import 'package:freelancer24_tycoon/views/world/team/employee_view.dart';

/// The "Team" tab of a city: hired employees and job applicants.
class EmployeesView extends StatefulWidget {
  final LocationDef location;

  const EmployeesView(this.location, {super.key});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  bool _applicants = false;

  @override
  Widget build(BuildContext context) {
    final applicants = context.select(
        (GameCubit c) => c.state.candidatesAt(widget.location.id).length);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SegmentedButton<bool>(
            segments: [
              const ButtonSegment(
                  value: false,
                  icon: Icon(Icons.badge_outlined),
                  label: Text('Your team')),
              ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text('Applicants ($applicants)')),
            ],
            selected: {_applicants},
            onSelectionChanged: (s) => setState(() => _applicants = s.first),
          ),
        ),
        Expanded(
          child: _applicants
              ? EmployeeOffersView(widget.location)
              : HiredEmployeesView(
                  widget.location,
                  onHire: () => setState(() => _applicants = true),
                ),
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
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          '${hired.length} employees · $slots of ${location.maxEmployees} desks',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (slots == 0 && hired.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Employees take contracts for you (no energy needed) '
              'and bring skills you don\'t have yet. Each one needs a desk.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final e in hired)
          EmployeeView(e, onFire: () => game.fireEmployee(e.id)),
        for (var i = hired.length; i < slots; i++)
          Card(
            child: ListTile(
              onTap: onHire,
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: const Icon(Icons.chair_outlined),
              ),
              title: const Text('Empty desk'),
              subtitle: const Text('Tap to see applicants'),
              trailing: Icon(Icons.person_add_alt_1, color: scheme.primary),
            ),
          ),
        if (slots < location.maxEmployees)
          Card(
            child: ListTile(
              enabled: state.balance >= slotCost,
              onTap: () => game.buyEmployeeSlot(location.id),
              leading: CircleAvatar(
                backgroundColor: scheme.surfaceContainerHighest,
                child: const Icon(Icons.add),
              ),
              title: Text('Buy a desk for ${dollar(slotCost)}'),
              subtitle: const Text('Room for one more employee'),
            ),
          ),
      ],
    );
  }
}
