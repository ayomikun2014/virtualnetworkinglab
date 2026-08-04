import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

/**
 * Callable Function (v2) allowing administrators to update user roles,
 * department assignments, and course permissions.
 *
 * Security Requirements:
 * - Caller must be authenticated.
 * - Caller must possess token claim `role === 'admin'`.
 */
export const setAdminUserRoleHandler = onCall(async (request) => {
  // 1. Verify caller authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication required. User must be logged in to invoke setAdminUserRole."
    );
  }

  // 2. Verify admin privilege
  const callerClaims = request.auth.token;
  if (callerClaims.role !== "admin") {
    logger.warn(`Permission denied: User '${request.auth.uid}' attempted setAdminUserRole without admin role.`);
    throw new HttpsError(
      "permission-denied",
      "Access denied. Only system administrators can modify user roles and permissions."
    );
  }

  const { targetUid, role, departmentId, assignedCourses } = request.data || {};

  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Missing or invalid 'targetUid' parameter."
    );
  }

  const validRoles = ["admin", "lecturer", "student"];
  if (!role || !validRoles.includes(role)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid 'role' parameter '${role}'. Must be one of: ${validRoles.join(", ")}`
    );
  }

  logger.info(`Admin '${request.auth.uid}' updating target user '${targetUid}' to role '${role}'.`);

  try {
    const db = admin.firestore();
    const userDocRef = db.doc(`virtuanetlab/app/users/${targetUid}`);

    // 3. Update Firestore user profile
    await userDocRef.set(
      {
        role,
        departmentId: departmentId || null,
        assignedCourses: Array.isArray(assignedCourses) ? assignedCourses : [],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: request.auth.uid,
      },
      { merge: true }
    );

    // 4. Update target user custom auth claims
    const newClaims = {
      role,
      vnl_auth: true,
      departmentId: departmentId || null,
    };

    await admin.auth().setCustomUserClaims(targetUid, newClaims);

    logger.info(`Successfully updated role and custom claims for user '${targetUid}'.`);

    return {
      success: true,
      targetUid,
      role,
      claims: newClaims,
      message: `Successfully updated user '${targetUid}' role to '${role}'.`,
    };
  } catch (error: any) {
    logger.error(`Error executing setAdminUserRole for targetUid '${targetUid}':`, error);
    throw new HttpsError("internal", `Failed to set user role: ${error.message}`);
  }
});
