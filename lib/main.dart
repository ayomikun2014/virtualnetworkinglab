import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/services/admin_seed_service.dart';
import 'firebase_options.dart';

/// Application Launch Entrypoint for VirtuaNetLab with Device Preview
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase Services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization fallback for local development or web
  }

  // 2. Execute Root Administrator Bootstrapping Seed Check
  try {
    final adminSeedService = AdminSeedService();
    await adminSeedService.bootstrapRootAdmin();
  } catch (_) {
    // Admin seeding fail-safe
  }

  // 3. Render Root Application Engine wrapped with DevicePreview for cross-device testing
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const VirtuaNetLabApp(),
    ),
  );
}
