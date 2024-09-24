import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/blocs/contracts/contract_bloc.dart';
import 'package:freelancer24_tycoon/blocs/employees/employee_bloc.dart';
import 'package:freelancer24_tycoon/blocs/locations/location_bloc.dart';
import 'package:freelancer24_tycoon/blocs/skills/skill_bloc.dart';
import 'package:freelancer24_tycoon/blocs/upgrades/upgrade_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/repositories/alert_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/contract_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/employee_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/location_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/skill_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/upgrade_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';
import 'package:freelancer24_tycoon/data/setup.dart';
import 'package:freelancer24_tycoon/observer.dart';
import 'package:freelancer24_tycoon/views/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  Bloc.observer = AppObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /* 
    repositories should only known about its own domain.
    Blocs should know about its own repository, other blocs, and its own service.
    Service should know about other services.
    Complicated tasks and heavy methods should be in services.
    Blocs should be the intermediate between the UI and the services

    */
    return ResponsiveSizer(builder: (context, orientation, screenType) {
      // repos

      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (context) => SkillRepository()),
          RepositoryProvider(create: (context) => UserRepository()),
          RepositoryProvider(create: (context) => LocationRepository()),
          RepositoryProvider(create: (context) => UpgradeRepository()),
          RepositoryProvider(create: (context) => ContractRepository()),
          RepositoryProvider(create: (context) => EmployeeRepository()),
          RepositoryProvider(create: (context) => AlertRepository()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AlertBloc>(
              create: (context) =>
                  AlertBloc(RepositoryProvider.of<AlertRepository>(context))
                    ..add(LoadAlertsEvent()),
            ),
            BlocProvider<SkillsBloc>(
              create: (context) => SkillsBloc(
                RepositoryProvider.of<SkillRepository>(context),
                RepositoryProvider.of<UserRepository>(context),
              )..add(LoadSkillsEvent()),
            ),
            BlocProvider<UserBloc>(
              create: (context) => UserBloc(
                  RepositoryProvider.of<UserRepository>(context),
                  RepositoryProvider.of<SkillRepository>(context),
                  RepositoryProvider.of<UpgradeRepository>(context))
                ..add(LoadUserEvent()),
            ),
            BlocProvider<LocationBloc>(
              create: (context) => LocationBloc(
                  RepositoryProvider.of<LocationRepository>(context),
                  RepositoryProvider.of<UserRepository>(context))
                ..add(LoadLocationsEvent()),
            ),
            BlocProvider<ContractBloc>(
              create: (context) => ContractBloc(
                RepositoryProvider.of<ContractRepository>(context),
                RepositoryProvider.of<UserRepository>(context),
                RepositoryProvider.of<LocationRepository>(context),
                RepositoryProvider.of<SkillRepository>(context),
                RepositoryProvider.of<EmployeeRepository>(context),
                RepositoryProvider.of<UpgradeRepository>(context),
              )..add(LoadContracsEvent()),
            ),
            BlocProvider<UpgradeBloc>(
              create: (context) => UpgradeBloc(
                  RepositoryProvider.of<UpgradeRepository>(context),
                  RepositoryProvider.of<UserRepository>(context))
                ..add(LoadUpgradesEvent()),
            ),
            BlocProvider<EmployeeBloc>(
              create: (context) => EmployeeBloc(
                RepositoryProvider.of<EmployeeRepository>(context),
                RepositoryProvider.of<AlertRepository>(context),
                RepositoryProvider.of<UserRepository>(context),
                RepositoryProvider.of<SkillRepository>(context),
              )..add(LoadEmployeesEvent()),
            )
          ],
          child: ResponsiveSizer(builder: (context, orientation, screenType) {
            return MaterialApp(
              title: 'Freelancer24 - Tycoon',
              debugShowCheckedModeBanner: false,
              theme: FlexThemeData.light(
                  useMaterial3: true,
                  scheme: FlexScheme.greenM3,
                  textTheme: GoogleFonts.robotoCondensedTextTheme(
                      Theme.of(context).textTheme)),
              darkTheme: FlexThemeData.dark(
                  useMaterial3: true, scheme: FlexScheme.orangeM3),
              themeMode: ThemeMode.light,
              home: const HomeView(),
            );
          }),
        ),
      );
    });
  }
}
