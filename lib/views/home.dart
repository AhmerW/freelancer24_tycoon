import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/utils/format.dart';
import 'package:freelancer24_tycoon/views/alerts/alerts_view.dart';
import 'package:freelancer24_tycoon/views/locations/locations_view.dart';
import 'package:freelancer24_tycoon/views/settings/settings_dialog.dart';
import 'package:freelancer24_tycoon/views/skills/skills_view.dart';
import 'package:freelancer24_tycoon/views/upgrades/upgrades_view.dart';
import 'package:freelancer24_tycoon/views/widgets/energybar.dart';
import 'package:freelancer24_tycoon/views/widgets/fade_indexed_stack.dart';
import 'package:google_fonts/google_fonts.dart';

const moneyColor = FlexColor.greenDarkPrimaryContainer;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 1;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FadeIndexedStack(
            index: _selectedIndex,
            duration: const Duration(milliseconds: 400),
            children: const [
              SkillsView(),
              LocationsView(),
              UpgradesView(),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BalanceWidget(),
                  const SizedBox(height: 8),
                  const EnergyBarWidget(),
                  IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SettingsDialog(),
                    ),
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 10, right: 10),
                child: AlertsView(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 80),
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'upgrades',
              onPressed: () => _select(2),
              child: Icon(_selectedIndex == 2
                  ? Icons.shopping_bag
                  : Icons.shopping_bag_outlined),
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'skills',
              onPressed: () => _select(0),
              child: Icon(_selectedIndex == 0
                  ? Icons.shopping_cart
                  : Icons.shopping_cart_outlined),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 40, bottom: 40),
            alignment: Alignment.bottomLeft,
            child: FloatingActionButton(
              heroTag: 'home',
              onPressed: () => _select(1),
              child:
                  Icon(_selectedIndex == 1 ? Icons.home : Icons.home_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceWidget extends StatelessWidget {
  const BalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.select((GameCubit c) => c.state.balance);
    final income = context.select((GameCubit c) => c.incomePerSecond);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2F7D3)),
      onPressed: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, color: moneyColor),
          const SizedBox(width: 5),
          AnimatedTextKit(
            // Restart the shimmer only when the shown text changes.
            key: ValueKey(formatMoney(balance)),
            repeatForever: false,
            totalRepeatCount: 1,
            pause: const Duration(milliseconds: 450),
            animatedTexts: [
              ColorizeAnimatedText(
                dollar(balance),
                textStyle: GoogleFonts.robotoCondensed(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                colors: [
                  moneyColor.withValues(alpha: 0.5),
                  moneyColor,
                  FlexColor.greenDarkPrimaryContainer,
                ],
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            '+${dollar(income)}/s',
            style: GoogleFonts.robotoCondensed(
              fontSize: 12,
              color: moneyColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
