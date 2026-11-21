import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:google_fonts/google_fonts.dart';

enum SkillStatus {
  unlocked,

  /// The next skill in line: can be unlocked once its requirement is met.
  next,

  /// Further down the line; shown as a teaser.
  locked,
}

class SkillWidget extends StatelessWidget {
  final SkillDef skill;
  final int level;
  final SkillStatus status;

  /// Why the skill can't be unlocked yet (ignoring money), if locked.
  final String? blocker;
  final double cost;
  final bool canAfford;
  final VoidCallback onPressed;

  const SkillWidget({
    super.key,
    required this.skill,
    required this.level,
    required this.status,
    required this.blocker,
    required this.cost,
    required this.canAfford,
    required this.onPressed,
  });

  bool get _unlocked => status == SkillStatus.unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = canAfford &&
        (_unlocked || (status == SkillStatus.next && blocker == null));

    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(15.0),
        color: Colors.grey[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: status == SkillStatus.locked
                  ? const Text('LOCKED')
                  : Text(
                      skill.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sansita(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                switch (status) {
                  SkillStatus.unlocked => skill.description,
                  SkillStatus.next => blocker ?? skill.description,
                  SkillStatus.locked => 'Unlock the previous skill first',
                },
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoCondensed(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: status == SkillStatus.next ? theme.primaryColor : null,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 15),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: status == SkillStatus.locked
                      ? null
                      : Opacity(
                          opacity: _unlocked ? 1 : 0.4,
                          child: Image.asset(
                            'assets/icons/skills/${skill.icon}',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                Expanded(
                  child: Center(
                    child: switch (status) {
                      SkillStatus.locked =>
                        const Icon(Icons.question_mark, size: 30),
                      SkillStatus.next => const SizedBox.shrink(),
                      SkillStatus.unlocked => AnimatedTextKit(
                          key: ValueKey(level),
                          repeatForever: false,
                          totalRepeatCount: 1,
                          pause: const Duration(milliseconds: 450),
                          animatedTexts: [
                            ColorizeAnimatedText(
                              'Level $level',
                              textStyle: GoogleFonts.robotoCondensed(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              colors: [
                                theme.primaryColor,
                                theme.cardColor,
                                theme.dividerColor,
                              ],
                            ),
                          ],
                        ),
                    },
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextButton(
                onPressed: enabled ? onPressed : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _unlocked
                          ? 'UPGRADE ${dollar(cost)}'
                          : 'UNLOCK ${dollar(cost)}',
                      style: GoogleFonts.robotoCondensed(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _unlocked
                          ? Icons.keyboard_double_arrow_up_sharp
                          : Icons.lock_outline,
                      size: _unlocked ? 30 : 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
        begin: const Offset(0.9, 0.9), duration: 300.ms, curve: Curves.easeIn);
  }
}
