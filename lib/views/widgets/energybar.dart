import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/engine/balance.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:google_fonts/google_fonts.dart';

const Color energyColor = Colors.black;

class EnergyBarWidget extends StatelessWidget {
  const EnergyBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final energy = context.select((GameCubit c) => c.state.energy.floor());
    const max = Balance.maxEnergy;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 240, 218, 109),
      ),
      onPressed: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: energyColor),
          const SizedBox(width: 6),
          SizedBox(
            width: 50,
            child: LinearProgressIndicator(
              value: energy / max,
              color: energyColor,
              backgroundColor: energyColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$energy/${max.toInt()}',
            style: GoogleFonts.robotoCondensed(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: energyColor,
            ),
          ),
        ],
      ),
    );
  }
}
