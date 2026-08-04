import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

/**
 * Firebase Auth Trigger triggered when a new user is created.
 * Reads newly created user profile from `/virtuanetlab/app/users/{uid}`
 * and provisions custom claims: `{ role, vnl_auth: true, departmentId }`.
 */
export const onUserCreatedHandler = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  logger.info(`Processing new user registration for UID: ${uid}`);

  try {
    const db = admin.firestore();
    const userDocRef = db.doc(`virtuanetlab/app/users/${uid}`);
    const userSnap = await userDocRef.get();

    const userData = userSnap.data() || {};
    const role = userData.role || "student";
    const departmentId = userData.departmentId || null;

    const customClaims = {
      role,
      vnl_auth: true,
      departmentId,
    };

    // Assign custom claims to Auth Token
    await admin.auth().setCustomUserClaims(uid, customClaims);

    // Record confirmation timestamp on user document
    await userDocRef.set(
      {
        customClaimsSet: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    logger.info(`Successfully set custom claims for user ${uid}:`, customClaims);
  } catch (error: any) {
    logger.error(`Error setting custom claims for user ${uid}:`, error);
  }
});

