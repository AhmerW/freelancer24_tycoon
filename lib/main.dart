import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/core/content/content_loader.dart';
import 'package:freelancer24_tycoon/core/engine/game_engine.dart';
import 'package:freelancer24_tycoon/core/save/hive_save_store.dart';
import 'package:freelancer24_tycoon/core/save/save_store.dart';
import 'package:freelancer24_tycoon/game/alert_cubit.dart';
import 'package:freelancer24_tycoon/game/game_cubit.dart';
import 'package:freelancer24_tycoon/views/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final content = await loadGameContent();
  final saves = SaveRepository(await HiveSaveStore.open());
  final engine = GameEngine(content);
  final saved = await saves.load();

  final game = GameCubit(
    engine: engine,
    saves: saves,
    initial: saved ?? engine.newGame(DateTime.now()),
  );
  // Subscribe to notices before the first tick so the "welcome back"
  // message isn't missed.
  final alerts = AlertCubit(game.notices);
  game.startTicking();

  runApp(FreelancerApp(game: game, alerts: alerts));
}

class FreelancerApp extends StatefulWidget {
  final GameCubit game;
  final AlertCubit alerts;

  const FreelancerApp({super.key, required this.game, required this.alerts});

  @override
  State<FreelancerApp> createState() => _FreelancerAppState();
}

class _FreelancerAppState extends State<FreelancerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.game.onResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        widget.game.onPaused();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.game),
        BlocProvider.value(value: widget.alerts),
      ],
      child: ResponsiveSizer(
        builder: (context, orientation, screenType) => MaterialApp(
          title: 'Freelancer24 - Tycoon',
          debugShowCheckedModeBanner: false,
          theme: FlexThemeData.light(
            useMaterial3: true,
            scheme: FlexScheme.greenM3,
            textTheme: GoogleFonts.robotoCondensedTextTheme(),
          ),
          darkTheme: FlexThemeData.dark(
            useMaterial3: true,
            scheme: FlexScheme.orangeM3,
          ),
          themeMode: ThemeMode.light,
          home: const HomeView(),
        ),
      ),
    );
  }
}
