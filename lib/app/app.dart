import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/topology/providers/topology_provider.dart';
import '../features/topology/providers/grading_provider.dart';
import '../features/exercises/providers/exercise_provider.dart';
import '../features/exercises/providers/progress_provider.dart';
import '../features/exercises/providers/save_history_provider.dart';
import 'app_routes.dart';
import 'theme/app_theme.dart';

/// VirtuaNetLab Root Application Widget with DevicePreview Configuration
class VirtuaNetLabApp extends StatefulWidget {
  const VirtuaNetLabApp({super.key});

  @override
  State<VirtuaNetLabApp> createState() => _VirtuaNetLabAppState();
}

class _VirtuaNetLabAppState extends State<VirtuaNetLabApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();

    // Built exactly once. GoRouter already reacts to AuthProvider via
    // `refreshListenable` below, re-running `redirect` whenever it calls
    // notifyListeners() — which a single login/register attempt does at
    // least twice (loading start, loading end). The previous code built this
    // router inside a `Consumer<AuthProvider>`, so every one of those calls
    // constructed a BRAND NEW GoRouter — a new Navigator and page stack —
    // which reset navigation back to `initialLocation` and discarded
    // whichever screen was on screen mid-flow, controllers and all. That's
    // what wiped the login/register form and bounced the user back to
    // /login partway through submitting it.
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => TopologyProvider()),
        ChangeNotifierProvider(create: (_) => GradingProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => SaveHistoryProvider()),
      ],
      child: MaterialApp.router(
        title: 'VirtuaNetLab — Virtual Network Laboratory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        routerConfig: _router,
      ),
    );
  }
}
