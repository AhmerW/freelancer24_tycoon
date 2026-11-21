import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';

enum SkillStatus {
  unlocked,

  /// Can be unlocked once its requirement is met.
  next,

  /// Further down the line; shown as a teaser.
  locked,
}

/// Shows a skill icon: a PNG from `assets/icons/skills/` or a named
/// Material icon (see [skillMaterialIcons]).
class SkillIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;

  const SkillIcon(this.icon, {super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    if (icon.endsWith('.png')) {
      return Image.asset('assets/icons/skills/$icon',
          width: size, height: size);
    }
    return Icon(
      skillMaterialIcons[icon] ?? Icons.school,
      size: size * 0.85,
      color: color ?? Colors.white,
      shadows: const [Shadow(color: GameColors.ink, offset: Offset(0, 2))],
    );
  }
}

/// Material icons usable by name in the game data. Listed explicitly so the
/// icon font can still be tree-shaken.
const Map<String, IconData> skillMaterialIcons = {
  'code': Icons.code,
  'web': Icons.web,
  'javascript': Icons.javascript,
  'storage': Icons.storage,
  'cloud': Icons.cloud,
  'dns': Icons.dns,
  'terminal': Icons.terminal,
  'data_object': Icons.data_object,
  'edit_note': Icons.edit_note,
  'article': Icons.article,
  'menu_book': Icons.menu_book,
  'translate': Icons.translate,
  'record_voice_over': Icons.record_voice_over,
  'campaign': Icons.campaign,
  'brush': Icons.brush,
  'palette': Icons.palette,
  'photo_camera': Icons.photo_camera,
  'design_services': Icons.design_services,
  'draw': Icons.draw,
  'view_in_ar': Icons.view_in_ar,
  'animation': Icons.animation,
  'movie': Icons.movie,
  'videocam': Icons.videocam,
  'mic': Icons.mic,
  'music_note': Icons.music_note,
  'podcast': Icons.podcasts,
  'graphic_eq': Icons.graphic_eq,
  'trending_up': Icons.trending_up,
  'insights': Icons.insights,
  'query_stats': Icons.query_stats,
  'ads_click': Icons.ads_click,
  'share': Icons.share,
  'mail': Icons.mail,
  'search': Icons.search,
  'analytics': Icons.analytics,
  'psychology': Icons.psychology,
  'smart_toy': Icons.smart_toy,
  'memory': Icons.memory,
  'phone_iphone': Icons.phone_iphone,
  'bug_report': Icons.bug_report,
  'school': Icons.school,
  'auto_awesome': Icons.auto_awesome,
  'lightbulb': Icons.lightbulb,
  'rocket_launch': Icons.rocket_launch,
  'public': Icons.public,
  'star': Icons.star,
  'emoji_events': Icons.emoji_events,
  'workspace_premium': Icons.workspace_premium,
  'military_tech': Icons.military_tech,
  'groups': Icons.groups,
  'payments': Icons.payments,
  'bolt': Icons.bolt,
  'location_city': Icons.location_city,
};

/// Price label with a coin, for buttons.
class PriceLabel extends StatelessWidget {
  final double price;
  final double size;

  const PriceLabel(this.price, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinIcon(size: size + 2),
        const SizedBox(width: 4),
        StrokeText(formatMoney(price), size: size),
      ],
    );
  }
}

class SkillCard extends StatelessWidget {
  final SkillDef skill;
  final int level;
  final SkillStatus status;

  /// Why the skill can't be unlocked yet (ignoring money), if locked.
  final String? blocker;
  final double cost;
  final bool canAfford;

  /// Income the next level (or unlocking) adds per second.
  final double incomeGain;

  /// Performs the upgrade/unlock; returns true on success.
  final bool Function() onPressed;
  final Color accent;

  const SkillCard({
    super.key,
    required this.skill,
    required this.level,
    required this.status,
    required this.blocker,
    required this.cost,
    required this.canAfford,
    required this.incomeGain,
    required this.onPressed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = status == SkillStatus.unlocked;
    final teaser = status == SkillStatus.locked;
    final actionable =
        unlocked || (status == SkillStatus.next && blocker == null);
    final tone = teaser ? GameTone.grey : GameTone.from(accent);
    final showBlocker = status == SkillStatus.next && blocker != null;

    final card = GamePanel(
      color: teaser ? GameColors.panelShade : GameColors.panel,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconBadge(
                tone: tone,
                size: 60,
                child: teaser
                    ? const Icon(Icons.lock, color: Colors.white, size: 28)
                    : Opacity(
                        opacity: unlocked ? 1 : 0.6,
                        child: SkillIcon(skill.icon, size: 38),
                      ),
              ),
              if (unlocked)
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: GameColors.gold,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GameColors.ink, width: 2),
                      ),
                      child: StrokeText('Lv $level', size: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrokeText(skill.name,
                    size: 18,
                    color: teaser ? const Color(0xFFE2E6EE) : Colors.white),
                const SizedBox(height: 2),
                Text(
                  showBlocker ? blocker! : skill.description,
                  style: GameFonts.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: showBlocker
                        ? GameColors.bad
                        : teaser
                            ? const Color(0xFF7D869A)
                            : GameColors.ink,
                  ),
                ),
                if (!teaser) ...[
                  const SizedBox(height: 3),
                  Text(
                    '+${dollar(incomeGain)}/s ${unlocked ? 'per level' : 'when learned'}',
                    style: GameFonts.body(
                        size: 12, color: const Color(0xFF2B8A1C)),
                  ),
                ],
              ],
            ),
          ),
          if (!teaser) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (buttonContext) => GameButton(
                tone: unlocked ? GameTone.green : GameTone.yellow,
                height: 56,
                width: 96,
                shine: actionable && canAfford,
                onPressed: actionable && canAfford
                    ? () {
                        if (!onPressed()) return;
                        final fx = Fx.of(buttonContext);
                        if (unlocked) {
                          fx.floatText(buttonContext, 'LEVEL ${level + 1}!',
                              color: GameColors.gold);
                        } else {
                          fx.floatText(buttonContext, 'NEW SKILL!',
                              color: GameColors.gold);
                          fx.confetti(buttonContext);
                        }
                      }
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StrokeText(unlocked ? 'UPGRADE' : 'LEARN', size: 13),
                    PriceLabel(cost, size: 15),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Pop the card whenever its level changes.
    return card.animate(key: ValueKey('${skill.id}-$level')).scaleXY(
        begin: 1.04, end: 1, duration: 280.ms, curve: Curves.easeOutBack);
  }
}
