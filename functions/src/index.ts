import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export Auth Triggers
export { onUserCreatedHandler as onUserCreated } from "./triggers/auth/onUserCreated";

// Export Callable Functions
export { setAdminUserRoleHandler as setAdminUserRole } from "./callables/setAdminUserRole";

// NOTE: `onSimulationQueueCreated` and the HMAC signing utilities were removed
// when the Python simulation engine was retired. Levels are now checked
// entirely client-side in Dart (see lib/core/checker/level_checker.dart), so
// there is no engine to dispatch to and no shared secret to sign with.
// Only the auth-related functions above remain.
