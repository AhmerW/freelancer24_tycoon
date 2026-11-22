import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/upgrades/ai_assistant_view.dart';
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
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: GameButton.small(
                  tone: _applicants ? GameTone.grey : GameTone.purple,
                  icon: Icons.badge,
                  label: 'YOUR TEAM',
                  onPressed: () => setState(() => _applicants = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GameButton.small(
                  tone: _applicants ? GameTone.purple : GameTone.grey,
                  icon: Icons.person_search,
                  label: 'APPLICANTS $applicants',
                  onPressed: () => setState(() => _applicants = true),
                ),
              ),
            ],
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      children: [
        Center(
          child: StrokeText(
              '${hired.length} STAFF · $slots/${location.maxEmployees} DESKS',
              size: 16),
        ),
        const SizedBox(height: 8),
        const AiAssistantCard(),
        if (slots == 0 && hired.isEmpty)
          GamePanel(
            color: const Color(0xFFEDE3FF),
            child: Text(
              'Employees take jobs for you (no energy needed!) and bring '
              "skills you don't have yet. Each one needs a desk.",
              textAlign: TextAlign.center,
              style: GameFonts.body(size: 14),
            ),
          ),
        for (final e in hired)
          EmployeeView(e, onFire: () => game.fireEmployee(e.id)),
        for (var i = hired.length; i < slots; i++)
          Bouncy(
            onTap: onHire,
            child: GamePanel(
              color: const Color(0xFFE3F6DD),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const IconBadge(
                    tone: GameTone.green,
                    size: 48,
                    child: Icon(Icons.chair, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Empty desk: tap to hire!',
                          style: GameFonts.display(
                              size: 17, color: GameColors.ink))),
                  const Icon(Icons.person_add_alt_1,
                      color: Color(0xFF2B8A1C), size: 28),
                ],
              ),
            ),
          ),
        if (slots < location.maxEmployees)
          GamePanel(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const IconBadge(
                  tone: GameTone.yellow,
                  size: 48,
                  child: Icon(Icons.add, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('New desk',
                      style:
                          GameFonts.display(size: 17, color: GameColors.ink)),
                ),
                GameButton(
                  tone: GameTone.yellow,
                  height: 46,
                  shine: state.balance >= slotCost,
                  onPressed: state.balance >= slotCost
                      ? () => game.buyEmployeeSlot(location.id)
                      : null,
                  child: PriceLabel(slotCost),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
