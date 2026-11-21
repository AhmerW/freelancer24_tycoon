import 'package:flutter/material.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

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
      size: size * 0.8,
      color: color ?? Theme.of(context).colorScheme.primary,
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
  'cloud': Icons.cloud_outlined,
  'dns': Icons.dns_outlined,
  'terminal': Icons.terminal,
  'data_object': Icons.data_object,
  'edit_note': Icons.edit_note,
  'article': Icons.article_outlined,
  'menu_book': Icons.menu_book_outlined,
  'translate': Icons.translate,
  'record_voice_over': Icons.record_voice_over_outlined,
  'campaign': Icons.campaign_outlined,
  'brush': Icons.brush_outlined,
  'palette': Icons.palette_outlined,
  'photo_camera': Icons.photo_camera_outlined,
  'design_services': Icons.design_services_outlined,
  'draw': Icons.draw_outlined,
  'view_in_ar': Icons.view_in_ar_outlined,
  'animation': Icons.animation,
  'movie': Icons.movie_outlined,
  'videocam': Icons.videocam_outlined,
  'mic': Icons.mic_none,
  'music_note': Icons.music_note_outlined,
  'podcast': Icons.podcasts,
  'graphic_eq': Icons.graphic_eq,
  'trending_up': Icons.trending_up,
  'insights': Icons.insights,
  'query_stats': Icons.query_stats,
  'ads_click': Icons.ads_click,
  'share': Icons.share_outlined,
  'mail': Icons.mail_outline,
  'search': Icons.search,
  'analytics': Icons.analytics_outlined,
  'psychology': Icons.psychology_outlined,
  'smart_toy': Icons.smart_toy_outlined,
  'memory': Icons.memory,
  'phone_iphone': Icons.phone_iphone,
  'bug_report': Icons.bug_report_outlined,
  'school': Icons.school_outlined,
  'auto_awesome': Icons.auto_awesome_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'rocket_launch': Icons.rocket_launch_outlined,
};

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
  final VoidCallback onPressed;
  final Color? accent;

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
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    final unlocked = status == SkillStatus.unlocked;
    final teaser = status == SkillStatus.locked;
    final actionable =
        unlocked || (status == SkillStatus.next && blocker == null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: teaser ? scheme.surfaceContainerLow : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: teaser ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: teaser
                  ? Icon(Icons.lock_outline, color: scheme.outline)
                  : Opacity(
                      opacity: unlocked ? 1 : 0.5,
                      child: SkillIcon(skill.icon, size: 36, color: color),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          skill.name,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (unlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Lv $level',
                              style: text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    switch (status) {
                      SkillStatus.unlocked => skill.description,
                      SkillStatus.next => blocker ?? skill.description,
                      SkillStatus.locked => skill.description,
                    },
                    style: text.bodySmall?.copyWith(
                      color: status == SkillStatus.next && blocker != null
                          ? scheme.error
                          : teaser
                              ? scheme.outline
                              : null,
                    ),
                  ),
                  if (!teaser) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${dollar(incomeGain)}/s ${unlocked ? 'per level' : 'when learned'}',
                      style: text.labelSmall
                          ?.copyWith(color: Colors.green.shade800),
                    ),
                  ],
                ],
              ),
            ),
            if (!teaser) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(84, 48),
                ),
                onPressed: actionable && canAfford ? onPressed : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(unlocked ? 'Upgrade' : 'Learn',
                        style: const TextStyle(fontSize: 12)),
                    Text(dollar(cost),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
