import pytest
import networkx as nx
from app.core.graph_parser import build_network_graph
from app.core.packet_tracer import simulate_icmp_ping


def test_simulate_icmp_ping_success():
    topology = {
        "nodes": [
            {
                "id": "pc1",
                "interfaces": [{"id": "eth0", "ip": "10.0.0.1/24", "status": "up"}],
            },
            {
                "id": "pc2",
                "interfaces": [{"id": "eth0", "ip": "10.0.0.2/24", "status": "up"}],
            },
        ],
        "cables": [
            {
                "fromNode": "pc1",
                "toNode": "pc2",
                "fromInterface": "eth0",
                "toInterface": "eth0",
            }
        ],
    }

    G = build_network_graph(topology)
    res = simulate_icmp_ping(G, "pc1", "pc2")

    assert res["success"] is True
    assert res["path"] == ["pc1", "pc2"]
    assert len(res["packet_stream"]) == 1
    assert res["packet_stream"][0]["status"] == "forwarded"
    assert res["packet_stream"][0]["packet"]["protocol"] == "ICMP"


def test_simulate_icmp_ping_no_path():
    topology = {
        "nodes": [
            {"id": "pc1", "interfaces": [{"id": "eth0", "ip": "10.0.0.1/24"}]},
            {"id": "pc2", "interfaces": [{"id": "eth0", "ip": "10.0.0.2/24"}]},
        ],
        "cables": [],  # Disconnected
    }

    G = build_network_graph(topology)
    res = simulate_icmp_ping(G, "pc1", "pc2")

    assert res["success"] is False
    assert res["drop_reason"] == "NO_PHYSICAL_ROUTE"
    assert "No physical or logical path found" in res["message"]


def test_simulate_icmp_ping_interface_down():
    topology = {
        "nodes": [
            {
                "id": "pc1",
                "interfaces": [{"id": "eth0", "ip": "10.0.0.1/24", "status": "down"}],
            },
            {
                "id": "pc2",
                "interfaces": [{"id": "eth0", "ip": "10.0.0.2/24", "status": "up"}],
            },
        ],
        "cables": [
            {
                "fromNode": "pc1",
                "toNode": "pc2",
                "fromInterface": "eth0",
                "toInterface": "eth0",
            }
        ],
    }

    G = build_network_graph(topology)
    res = simulate_icmp_ping(G, "pc1", "pc2")

    assert res["success"] is False
    assert "administratively down" in res["drop_reason"]


def test_simulate_icmp_ping_acl_deny():
    topology = {
        "nodes": [
            {
                "id": "router",
                "interfaces": [
                    {
                        "id": "eth0",
                        "ip": "10.0.0.1/24",
                        "status": "up",
                        "acls": [
                            {"action": "deny", "protocol": "icmp", "src": "any", "dst": "any"}
                        ],
                    }
                ],
            },
            {
                "id": "server",
                "interfaces": [{"id": "eth0", "ip": "10.0.0.2/24", "status": "up"}],
            },
        ],
        "cables": [
            {
                "fromNode": "router",
                "toNode": "server",
                "fromInterface": "eth0",
                "toInterface": "eth0",
            }
        ],
    }

    G = build_network_graph(topology)
    res = simulate_icmp_ping(G, "router", "server")

    assert res["success"] is False
    assert "dropped by ACL" in res["drop_reason"]
