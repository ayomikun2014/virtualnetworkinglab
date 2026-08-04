import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/topology/providers/topology_provider.dart';
import '../features/exercises/providers/exercise_provider.dart';
import 'app_routes.dart';
import 'theme/app_theme.dart';

/// VirtuaNetLab Root Application Widget with DevicePreview Configuration
class VirtuaNetLabApp extends StatelessWidget {
  const VirtuaNetLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TopologyProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = AppRouter.createRouter(authProvider);

          return MaterialApp.router(
            title: 'VirtuaNetLab — Virtual Network Laboratory',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
