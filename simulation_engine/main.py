import uuid
import logging
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.core.config import settings
from app.api.middleware.hmac_auth import verify_hmac_signature
from app.core.graph_parser import build_network_graph
from app.core.packet_tracer import simulate_icmp_ping
from app.core.auto_grader import evaluate_grading_criteria
from app.services.storage_service import upload_simulation_artifacts

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("simulation_engine")

app = FastAPI(
    title="VirtuaNetLab Python Simulation Engine",
    version="1.0.0",
    docs_url="/docs" if settings.ENV == "development" else None,
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SimulationRequest(BaseModel):
    queueId: Optional[str] = Field(default="", description="ID from simulation queue")
    userId: Optional[str] = Field(default="anonymous", description="User ID requesting simulation")
    topologyData: Dict[str, Any] = Field(..., description="Flutter topology JSON containing nodes and cables")
    targetCriteria: List[Dict[str, Any]] = Field(default=[], description="Auto-grading target criteria list")
    pingSource: Optional[str] = Field(default=None, description="Optional explicit source node for ICMP ping")
    pingTarget: Optional[str] = Field(default=None, description="Optional explicit target node for ICMP ping")


@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "VirtuaNetLab Simulation Engine",
        "environment": settings.ENV,
        "engine": "Python 3.11 / Scapy / NetworkX",
    }


@app.post(
    "/api/v1/simulate",
    tags=["Simulation"],
    dependencies=[Depends(verify_hmac_signature)],
)
async def run_simulation(payload: SimulationRequest):
    """
    Primary simulation webhook triggered asynchronously from Firebase Cloud Functions.
    Processes network topology, synthesizes Scapy ICMP packets, evaluates auto-grading rules,
    uploads logs to Cloud Storage, and returns complete evaluation summary.
    """
    simulation_id = str(uuid.uuid4())
    logger.info(f"Starting simulation {simulation_id} for queueId: {payload.queueId}")

    stdout_lines = [f"[START] Simulation ID: {simulation_id}"]
    stderr_lines = []

    try:
        # 1. Build NetworkX Graph from Topology JSON
        stdout_lines.append("[1/4] Parsing topology data into NetworkX directed graph...")
        G = build_network_graph(payload.topologyData)
        stdout_lines.append(f"     Graph created with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges.")

        # 2. Scapy ICMP Packet Trace Simulation
        stdout_lines.append("[2/4] Executing ICMP Scapy packet trace simulation...")
        ping_result = {}
        src_node = payload.pingSource
        dst_node = payload.pingTarget

        if not src_node or not dst_node:
            nodes = list(G.nodes())
            if len(nodes) >= 2:
                src_node, dst_node = nodes[0], nodes[-1]

        if src_node and dst_node:
            ping_result = simulate_icmp_ping(G, src_node, dst_node)
            stdout_lines.append(f"     Ping ({src_node} -> {dst_node}): " + ("SUCCESS" if ping_result.get("success") else "FAILED"))
        else:
            stdout_lines.append("     Skipped explicit ping test (fewer than 2 nodes in graph).")

        packet_stream = ping_result.get("packet_stream", [])

        # 3. Auto-Grading Evaluation
        stdout_lines.append("[3/4] Evaluating auto-grading criteria...")
        grading_results = evaluate_grading_criteria(G, payload.targetCriteria)
        stdout_lines.append(f"     Score: {grading_results['totalScore']}/{grading_results['maxScore']} ({grading_results['percentage']}%)")

        # 4. Assemble Summary
        summary = {
            "simulationId": simulation_id,
            "queueId": payload.queueId,
            "userId": payload.userId,
            "nodesCount": G.number_of_nodes(),
            "edgesCount": G.number_of_edges(),
            "pingResult": ping_result,
            "grading": grading_results,
            "status": "success",
        }

        stdout_lines.append("[4/4] Uploading simulation artifacts to Cloud Storage & Firestore...")
        storage_info = upload_simulation_artifacts(
            simulation_id=simulation_id,
            queue_id=payload.queueId,
            user_id=payload.userId,
            summary=summary,
            stdout_log="\n".join(stdout_lines) + "\n",
            stderr_log="\n".join(stderr_lines) + "\n",
            packet_stream=packet_stream,
        )

        summary["storage"] = storage_info
        logger.info(f"Simulation {simulation_id} completed successfully.")
        return summary

    except Exception as e:
        logger.exception(f"Simulation {simulation_id} encountered an error: {e}")
        stderr_lines.append(f"[ERROR] {str(e)}")

        error_summary = {
            "simulationId": simulation_id,
            "queueId": payload.queueId,
            "userId": payload.userId,
            "status": "error",
            "error": str(e),
        }

        upload_simulation_artifacts(
            simulation_id=simulation_id,
            queue_id=payload.queueId,
            user_id=payload.userId,
            summary=error_summary,
            stdout_log="\n".join(stdout_lines) + "\n",
            stderr_log="\n".join(stderr_lines) + "\n",
            packet_stream=[],
        )

        raise HTTPException(
            status_code=500,
            detail=f"Simulation processing error: {str(e)}",
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=(settings.ENV == "development"))
