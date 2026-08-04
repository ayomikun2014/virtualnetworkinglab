import pytest
from fastapi.testclient import TestClient
from main import app
from app.core.config import settings

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "VirtuaNetLab Simulation Engine"


def test_simulate_endpoint_dev_mode():
    settings.ENV = "development"

    payload = {
        "queueId": "q_101",
        "userId": "usr_202",
        "topologyData": {
            "nodes": [
                {"id": "r1", "type": "router", "interfaces": [{"id": "e0", "ip": "10.0.0.1/24"}]},
                {"id": "r2", "type": "router", "interfaces": [{"id": "e0", "ip": "10.0.0.2/24"}]},
            ],
            "cables": [
                {"fromNode": "r1", "toNode": "r2", "fromInterface": "e0", "toInterface": "e0"}
            ],
        },
        "targetCriteria": [],
        "pingSource": "r1",
        "pingTarget": "r2",
    }

    response = client.post("/api/v1/simulate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["nodesCount"] == 2
    assert data["edgesCount"] == 2
    assert data["pingResult"]["success"] is True
