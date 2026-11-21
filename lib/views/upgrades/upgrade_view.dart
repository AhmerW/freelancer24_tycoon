import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/core/state/game_state.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/widgets/energybar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class UpgradeView extends StatelessWidget {
  final UpgradeLineDef line;
  final Color color;

  const UpgradeView(this.line, {super.key, required this.color});

  String get _title =>
      line.category[0].toUpperCase() + line.category.substring(1);

  String get _effectLabel => switch (line.effect) {
        UpgradeEffect.income => 'income',
        UpgradeEffect.energyRegen => 'energy regen',
      };

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.upgrades[line.id] != b.upgrades[line.id] ||
          a.balance.floor() != b.balance.floor(),
      builder: (context, state) {
        final engine = game.engine;
        final progress = state.upgrades[line.id]!;
        final item = engine.currentItem(state, line);
        final next = engine.nextItem(state, line);
        final maxLevel = engine.maxItemLevel(state, line);
        final atMax = progress.level >= maxLevel;
        final bonus = engine.upgradeBonus(state, line.effect);

        final String buttonText;
        final double? cost;
        final VoidCallback? action;
        if (!atMax) {
          cost = engine.upgradeLevelCost(item, progress.level);
          buttonText = 'Upgrade for ${dollar(cost)}';
          action = () => game.upgradeItemLevel(line.id);
        } else if (next != null) {
          cost = next.price;
          buttonText = 'Buy ${next.name} for ${dollar(cost)}';
          action = () => game.buyNextItem(line.id);
        } else {
          cost = null;
          buttonText = 'MAX';
          action = null;
        }
        final canAfford = cost != null && state.balance >= cost;

        return Container(
          width: 85.w,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: FlexColor.lightScaffoldBackground,
            boxShadow: kElevationToShadow[4],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Text(
                      _title,
                      style: GoogleFonts.robotoCondensed(
                          fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Image.asset(
                                'assets/icons/upgrades/${line.category}/${item.icon}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.description,
                                style: GoogleFonts.robotoCondensed(
                                  fontSize: 15.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '+${bonus.toStringAsFixed(0)}% $_effectLabel'
                '${atMax ? '' : '  (+${item.rate.toStringAsFixed(0)}% per level)'}',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 15,
                  color: energyColor,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedTextKit(
                key: ValueKey(progress),
                repeatForever: false,
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 50),
                animatedTexts: [
                  ColorizeAnimatedText(
                    'Level ${progress.level} / $maxLevel',
                    colors: [color, color.withValues(alpha: 0.5)],
                    speed: const Duration(milliseconds: 100),
                    textStyle: GoogleFonts.robotoCondensed(fontSize: 15),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  color: color,
                  value: progress.level / maxLevel,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? action : null,
                    child: Text(buttonText, textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
