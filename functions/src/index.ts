import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export Auth Triggers
export { onUserCreatedHandler as onUserCreated } from "./triggers/auth/onUserCreated";

// Export Firestore Triggers
export { onSimulationQueueCreatedHandler as onSimulationQueueCreated } from "./triggers/firestore/onSimulationQueue";

// Export Callable Functions
export { setAdminUserRoleHandler as setAdminUserRole } from "./callables/setAdminUserRole";
