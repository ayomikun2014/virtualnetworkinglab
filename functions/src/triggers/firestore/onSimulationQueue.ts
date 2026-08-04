import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import axios from "axios";

import { HMAC_SECRET_KEY, FASTAPI_ENGINE_URL } from "../../config/env";
import { generateHmacSignature } from "../../utils/hmac";

/**
 * Firestore Trigger (v2) triggered when a new simulation job is enqueued in
 * `/virtuanetlab/app/simulation_queue/{queueId}`.
 *
 * THIS IS THE ONLY DISPATCHER. The Flutter client used to also POST directly to
 * the engine, so two simulations ran per click and raced on this document. That
 * path has been deleted. The client's only job is to write the queue document.
 *
 * Workflow:
 * 1. Fetches topology JSON from `/virtuanetlab/app/topologies/{topologyId}`.
 * 2. Resolves the grading criteria SERVER-SIDE, from either the level or the
 *    exercise solution key. Criteria are never taken from the client.
 * 3. Updates queue document status to `'processing'`.
 * 4. Generates HMAC-SHA256 signature header.
 * 5. Dispatches HTTP POST payload to Python FastAPI Engine on Cloud Run.
 * 6. Handles timeout / connection error fallbacks by marking status as `'failed'`.
 */
export const onSimulationQueueCreatedHandler = onDocumentCreated(
  {
    document: "virtuanetlab/app/simulation_queue/{queueId}",
    secrets: [HMAC_SECRET_KEY],
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("onSimulationQueueCreated triggered without document data.");
      return;
    }

    const queueId = event.params.queueId;
    const queueData = snap.data();
    const { topologyId, exerciseId, levelId, topicId, userId, pingSource, pingTarget } =
      queueData;

    logger.info(`Processing simulation queue job: ${queueId}`, {
      topologyId,
      exerciseId,
      levelId,
      userId,
    });

    const db = admin.firestore();
    const queueDocRef = db.doc(`virtuanetlab/app/simulation_queue/${queueId}`);

    try {
      // 1. Update queue status to 'processing'
      await queueDocRef.update({
        status: "processing",
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Fetch associated network topology
      let topologyData: Record<string, any> = {};
      if (topologyId) {
        const topSnap = await db.doc(`virtuanetlab/app/topologies/${topologyId}`).get();
        if (topSnap.exists) {
          const rawTop = topSnap.data() || {};
          topologyData = rawTop.topologyData || rawTop;
        } else {
          logger.warn(`Topology document '${topologyId}' not found for queue item '${queueId}'.`);
        }
      }

      // 3. Resolve grading criteria SERVER-SIDE.
      //
      // The client sends only `levelId` / `exerciseId`, never the criteria
      // themselves. If it did, a student could submit an empty criteria list
      // and score 100% on every level.
      let targetCriteria: any[] = [];
      let passMark = 70; // default pass mark, may be overridden per level

      if (levelId) {
        const levelSnap = await db.doc(`virtuanetlab/app/levels/${levelId}`).get();
        if (levelSnap.exists) {
          const level = levelSnap.data() || {};
          targetCriteria = level.successCriteria || [];
          if (typeof level.passMark === "number") {
            passMark = level.passMark;
          }
          logger.info(
            `Loaded ${targetCriteria.length} criteria for level '${levelId}' (passMark ${passMark}).`
          );
        } else {
          logger.warn(`Level document '${levelId}' not found for queue item '${queueId}'.`);
        }
      } else if (exerciseId) {
        const solutionSnap = await db.doc(`virtuanetlab/app/exercises/${exerciseId}/private/solution_key`).get();
        if (solutionSnap.exists) {
          const rawSol = solutionSnap.data() || {};
          targetCriteria = rawSol.gradingCriteria || rawSol.targetCriteria || [];
        } else {
          logger.info(`No private solution key found for exercise '${exerciseId}'. Using default evaluation.`);
        }
      }

      // 4. Assemble payload for Python FastAPI engine
      const payload = {
        queueId,
        userId: userId || "anonymous",
        topologyData,
        targetCriteria,
        passMark,
        levelId: levelId || null,
        topicId: topicId || null,
        pingSource: pingSource || null,
        pingTarget: pingTarget || null,
      };

      // 5. Compute HMAC-SHA256 signature.
      //
      // No default fallback secret: an unset secret is a deployment fault and
      // must fail loudly rather than silently signing with a value that is
      // published in the source tree.
      const secret = HMAC_SECRET_KEY.value() || process.env.HMAC_SECRET_KEY;
      if (!secret || secret === "vnl-default-secret-key-change-in-production") {
        throw new Error(
          "HMAC_SECRET_KEY is unset or still the default placeholder. Set a real " +
            "secret via Secret Manager before dispatching simulations."
        );
      }
      const signatureHeader = generateHmacSignature(payload, secret);

      // 6. Post request to Python FastAPI Cloud Run engine
      const targetUrl = `${FASTAPI_ENGINE_URL}/api/v1/simulate`;
      logger.info(`Dispatching simulation job '${queueId}' to ${targetUrl}`);

      const response = await axios.post(targetUrl, payload, {
        headers: {
          "Content-Type": "application/json",
          "X-VNL-Signature": signatureHeader,
        },
        timeout: 45000, // 45 second timeout
      });

      logger.info(`Simulation engine processed job '${queueId}' successfully:`, response.data?.simulationId);
    } catch (error: any) {
      const errorMessage = error?.response?.data?.detail || error?.message || "Unknown error during simulation engine dispatch.";
      logger.error(`Simulation processing failed for queueId '${queueId}':`, errorMessage);

      await queueDocRef.update({
        status: "failed",
        error: errorMessage,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
