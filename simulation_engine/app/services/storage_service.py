import json
import logging
from datetime import datetime, timezone
import firebase_admin
from firebase_admin import credentials, storage, firestore
from app.core.config import settings

logger = logging.getLogger(__name__)


def _ensure_firebase_app():
    try:
        firebase_admin.get_app()
    except ValueError:
        options = {}
        if settings.FIREBASE_STORAGE_BUCKET:
            options["storageBucket"] = settings.FIREBASE_STORAGE_BUCKET

        # Initialize with Default Application Credentials (GCP/Cloud Run/Local ADC)
        try:
            firebase_admin.initialize_app(options=options)
        except Exception as e:
            logger.warning(f"Firebase initialize_app warning: {e}")


def upload_simulation_artifacts(
    simulation_id: str,
    queue_id: str,
    user_id: str,
    summary: dict,
    stdout_log: str,
    stderr_log: str,
    packet_stream: list,
) -> dict:
    """
    Uploads execution outputs to Firebase Cloud Storage and updates Firestore documents.

    Storage Path:
        virtuanetlab/app/simulation_logs/{YYYY}/{MM}/{DD}/{simulationId}/

    Firestore Updates:
        - /virtuanetlab/app/simulation_results/{simulation_id}
        - /virtuanetlab/app/simulation_queue/{queue_id}
    """
    _ensure_firebase_app()

    now = datetime.now(timezone.utc)
    date_path = now.strftime("%Y/%m/%d")
    base_storage_path = f"virtuanetlab/app/simulation_logs/{date_path}/{simulation_id}"


    artifacts = {
        "summary.json": (json.dumps(summary, indent=2), "application/json"),
        "stdout.log": (stdout_log or "[STDOUT] Simulation executed successfully.\n", "text/plain"),
        "stderr.log": (stderr_log or "", "text/plain"),
        "packet_stream.json": (json.dumps(packet_stream, indent=2), "application/json"),
    }

    uploaded_urls = {}

    try:
        bucket = storage.bucket() if settings.FIREBASE_STORAGE_BUCKET else None
        if bucket:
            for file_name, (content, content_type) in artifacts.items():
                blob_path = f"{base_storage_path}/{file_name}"
                blob = bucket.blob(blob_path)
                blob.upload_from_string(content, content_type=content_type)
                uploaded_urls[file_name] = blob.public_url if blob.public_url else blob_path
    except Exception as e:
        logger.error(f"Cloud Storage upload failed (continuing with Firestore update): {e}")

    # Update Firestore
    try:
        db = firestore.client()

        summary_status = summary.get("status", "success") if isinstance(summary, dict) else "success"
        queue_status = "failed" if summary_status in ("error", "failed") else "completed"

        result_doc_ref = db.collection("virtuanetlab").document("app").collection("simulation_results").document(simulation_id)
        result_payload = {
            "simulationId": simulation_id,
            "queueId": queue_id,
            "userId": user_id,
            "summary": summary,
            "artifacts": uploaded_urls,
            "baseStoragePath": base_storage_path,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "status": queue_status,
        }
        result_doc_ref.set(result_payload, merge=True)

        if queue_id:
            queue_doc_ref = db.collection("virtuanetlab").document("app").collection("simulation_queue").document(queue_id)
            queue_payload = {
                "status": queue_status,
                "completedAt": firestore.SERVER_TIMESTAMP,
                "resultId": simulation_id,
            }
            if queue_status == "failed" and isinstance(summary, dict) and "error" in summary:
                queue_payload["error"] = summary["error"]
            queue_doc_ref.set(queue_payload, merge=True)

    except Exception as e:
        logger.error(f"Firestore update failed: {e}")

    return {
        "baseStoragePath": base_storage_path,
        "uploadedArtifacts": list(uploaded_urls.keys()),
    }

