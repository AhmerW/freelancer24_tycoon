import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';
import 'package:freelancer24_tycoon/views/world/contracts/offer_view.dart';

/// Big team projects in a city: they take hours and need 2+ people, pay more
/// than a job in total and always leave a gift chest. Good to start before
/// leaving the game.
class ProjectsView extends StatelessWidget {
  final LocationDef location;
  final VoidCallback onAccepted;

  const ProjectsView(this.location, {super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final projects = game.state.projectsAt(location.id);
    final nextAt = game.state.locations[location.id]!.nextProjectAt;
    final nextIn = nextAt?.difference(game.now()) ?? Duration.zero;

    final intro = GamePanel(
      color: const Color(0xFFF6EEFF),
      borderColor: GameTone.purple.lip,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconBadge(
            tone: GameTone.purple,
            size: 44,
            child: const Icon(Icons.rocket_launch, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Projects take longer and need a team, but pay more and always '
              'leave a gift chest. Start one before you take a break!',
              style: GameFonts.body(size: 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        intro,
        if (projects.isEmpty)
          SizedBox(
            height: 220,
            child: EmptyState(
              icon: Icons.rocket_launch_outlined,
              message: 'No projects right now.\n'
                  'A new one comes in ${formatDuration(nextIn)}.',
            ),
          ),
        for (final project in projects)
          OfferView(
            key: ValueKey(project.id),
            offer: project,
            location: location,
            onAccepted: onAccepted,
          ),
        if (projects.isNotEmpty &&
            projects.length < location.maxProjects &&
            !nextIn.isNegative)
          Padding(
            padding: const EdgeInsets.all(12),
            child: StrokeText(
              'Next project in ${formatDuration(nextIn)}',
              size: 16,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
