import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/contracts_view.dart';
import 'package:freelancer24_tycoon/views/locations/contracts/offers_view.dart';
import 'package:freelancer24_tycoon/views/locations/employees/employees_view.dart';
import 'package:freelancer24_tycoon/views/locations/marketing_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

enum _Section { menu, offers, contracts, employees }

class LocationView extends StatefulWidget {
  final LocationDef location;
  final VoidCallback onClose;

  const LocationView(this.location, {super.key, required this.onClose});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  _Section _section = _Section.menu;

  void _show(_Section s) => setState(() => _section = s);

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final unlocked = context
        .select((GameCubit c) => c.state.isLocationUnlocked(location.id));

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/locations/${location.icon}',
              width: 70,
              height: 70,
              color: Colors.grey.withValues(alpha: 0.1),
              repeat: ImageRepeat.repeat,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              AnimatedTextKit(
                repeatForever: false,
                totalRepeatCount: 1,
                animatedTexts: [
                  TyperAnimatedText(
                    '${location.city}, ${location.country}',
                    speed: const Duration(milliseconds: 50),
                    textStyle: GoogleFonts.robotoCondensed(fontSize: 20.sp),
                  ),
                ],
              ),
              Text(
                'Freelance Portal V.1.0',
                style: GoogleFonts.robotoCondensed(fontSize: 15.sp),
              ),
              const Divider(),
              Expanded(
                child: !unlocked
                    ? LockedLocationView(location)
                    : switch (_section) {
                        _Section.menu => _Menu(location, onSelect: _show),
                        _Section.offers => OffersView(
                            location,
                            onBack: () => _show(_Section.menu),
                            onShowContracts: () => _show(_Section.contracts),
                          ),
                        _Section.contracts => ContractsView(
                            location,
                            onBack: () => _show(_Section.menu),
                          ),
                        _Section.employees => EmployeesView(
                            location,
                            onBack: () => _show(_Section.menu),
                          ),
                      },
              ),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final LocationDef location;
  final void Function(_Section) onSelect;

  const _Menu(this.location, {required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final offers =
        context.select((GameCubit c) => c.state.offersAt(location.id).length);
    final running = context
        .select((GameCubit c) => c.state.runningContractsAt(location.id));
    final ready = running.where((c) => c.isCompleted).length;
    final staff =
        context.select((GameCubit c) => c.state.hiredAt(location.id).length);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const MarketingView(),
          const SizedBox(height: 15),
          LocationOptionButton(
            onPressed: () => onSelect(_Section.offers),
            text: 'Available offers ($offers)',
            icon: Icons.work_outline,
          ),
          LocationOptionButton(
            onPressed: () => onSelect(_Section.contracts),
            text: ready > 0
                ? 'Contracts ($ready ready to collect!)'
                : 'Ongoing contracts (${running.length})',
            icon: Icons.description_outlined,
            highlight: ready > 0,
          ),
          LocationOptionButton(
            onPressed: () => onSelect(_Section.employees),
            text: 'Manage employees ($staff)',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }
}

class LocationOptionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String text;
  final bool highlight;

  const LocationOptionButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 90,
      width: 90.w,
      child: ElevatedButton(
        style: highlight
            ? ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade200)
            : null,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.robotoCondensed(fontSize: 17.sp),
              ),
            ),
            const SizedBox(width: 20),
            Icon(icon),
          ],
        ),
      ),
    );
  }
}

class LockedLocationView extends StatelessWidget {
  final LocationDef location;

  const LockedLocationView(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    final canAfford =
        context.select((GameCubit c) => c.state.balance >= location.price);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            location.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoCondensed(fontSize: 17.sp),
          ),
        ),
        const Icon(Icons.lock, size: 40),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: canAfford
              ? () => context.read<GameCubit>().unlockLocation(location.id)
              : null,
          child: Text('Unlock for ${dollar(location.price)}'),
        ),
        const SizedBox(height: 8),
        Text(
          'Contracts here pay ${location.rate}x',
          style: GoogleFonts.robotoCondensed(fontSize: 15.sp),
        ),
      ],
    );
  }
}
