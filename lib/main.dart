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

  // Starter Free Practice levels are NOT seeded here.
  //
  // This point in startup is before runApp, so nobody is signed in yet. Any
  // Firestore ruleset that requires an authenticated request rejects every
  // write made from here — silently, since seeding can't be allowed to
  // block launch — which is exactly why Free Practice stayed empty with no
  // visible error. `ExerciseProvider.fetchPracticeLevels()` now seeds
  // lazily instead, as the signed-in user, and surfaces failures.

  // 3. Render Root Application Engine wrapped with DevicePreview for cross-device testing
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const VirtuaNetLabApp(),
    ),
  );
}
