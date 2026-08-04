import pytest
from app.services.storage_service import upload_simulation_artifacts


def test_upload_simulation_artifacts_structure():
    summary = {
        "simulationId": "sim_123",
        "queueId": "q_456",
        "userId": "user_789",
        "status": "success",
    }

    res = upload_simulation_artifacts(
        simulation_id="sim_123",
        queue_id="q_456",
        user_id="user_789",
        summary=summary,
        stdout_log="stdout test log",
        stderr_log="",
        packet_stream=[],
    )

    assert "baseStoragePath" in res
    assert "virtuanetlab/app/simulation_logs/" in res["baseStoragePath"]
    assert "sim_123" in res["baseStoragePath"]
