import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/game_content.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/game_ui/fx_layer.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_button.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_panel.dart';
import 'package:freelancer24_tycoon/views/game_ui/game_theme.dart';
import 'package:freelancer24_tycoon/views/game_ui/stroke_text.dart';
import 'package:freelancer24_tycoon/views/skills/skills_widgets.dart';
import 'package:freelancer24_tycoon/views/widgets/stat_chip.dart';

/// The "Ads" tab of a city: marketing campaigns that bring more and better
/// offers for a while.
class CampaignsView extends StatelessWidget {
  final LocationDef location;

  const CampaignsView(this.location, {super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      children: [
        const Center(
          child: StrokeText('Ads bring more (and better) clients!', size: 16),
        ),
        const SizedBox(height: 10),
        for (final c in game.content.campaigns) _CampaignCard(location, c),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final LocationDef location;
  final CampaignDef campaign;

  const _CampaignCard(this.location, this.campaign);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameCubit>();
    final state = game.state;
    final now = game.now();
    final running =
        game.engine.activeCampaign(state, location.id, campaign.id, now);
    final cost = game.engine.campaignCost(state, campaign);
    final canStart = running == null &&
        game.engine.campaignBlocker(state, location.id, campaign, now) ==
            null &&
        state.balance >= cost;

    final effects = <Widget>[
      if (campaign.extraOffers > 0)
        StatChip(
            icon: Icons.add_box,
            label: '+${campaign.extraOffers} offers',
            color: const Color(0xFF2E8BEA)),
      if (campaign.offerCooldownMultiplier < 1)
        StatChip(
            icon: Icons.fast_forward,
            label:
                '${(1 / campaign.offerCooldownMultiplier).toStringAsFixed(1)}x faster',
            color: const Color(0xFF6A2DB8)),
      if (campaign.payMultiplier > 1)
        StatChip(
            icon: Icons.attach_money,
            label: '+${((campaign.payMultiplier - 1) * 100).round()}% pay',
            color: const Color(0xFF2B8A1C)),
      if (campaign.goldenChanceBonus > 0)
        StatChip(
            icon: Icons.star,
            label: '+${(campaign.goldenChanceBonus * 100).round()}% VIP',
            color: const Color(0xFFE09B00)),
      StatChip(
          icon: Icons.schedule,
          label: formatDuration(campaign.duration),
          color: const Color(0xFF5A6478)),
    ];

    return GamePanel(
      color: running != null ? const Color(0xFFE3F6DD) : GameColors.panel,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                tone: GameTone.red,
                size: 52,
                child: SkillIcon(campaign.icon, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeText(campaign.name, size: 19),
                    Text(campaign.description, style: GameFonts.body(size: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: effects),
          const SizedBox(height: 10),
          if (running != null)
            GameProgressBar(
              value: 1 -
                  running.remaining(now).inMilliseconds /
                      campaign.duration.inMilliseconds,
              tone: GameTone.green,
              height: 26,
              label: 'LIVE · ${formatDuration(running.remaining(now))} left',
            )
          else
            Builder(
              builder: (buttonContext) => GameButton(
                tone: GameTone.red,
                height: 52,
                shine: canStart,
                onPressed: canStart
                    ? () {
                        if (game.startCampaign(location.id, campaign.id)) {
                          Fx.of(buttonContext).floatText(
                              buttonContext, 'CAMPAIGN LIVE!',
                              color: GameColors.gold);
                        }
                      }
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign, color: Colors.white),
                    const SizedBox(width: 6),
                    const StrokeText('LAUNCH', size: 17),
                    const SizedBox(width: 10),
                    PriceLabel(cost),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
