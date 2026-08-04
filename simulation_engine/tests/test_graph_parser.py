import pytest
import networkx as nx
from app.core.graph_parser import build_network_graph


def test_build_network_graph_basic():
    topology_data = {
        "nodes": [
            {
                "id": "router_1",
                "name": "Router 1",
                "type": "router",
                "interfaces": [
                    {
                        "id": "eth0",
                        "ip": "192.168.1.1/24",
                        "mac": "00:11:22:33:44:55",
                        "vlan": 10,
                        "status": "up",
                    }
                ],
                "ospf_enabled": True,
            },
            {
                "id": "host_1",
                "name": "Host 1",
                "type": "host",
                "interfaces": [
                    {
                        "id": "eth0",
                        "ip": "192.168.1.10/24",
                        "mac": "AA:BB:CC:DD:EE:FF",
                    }
                ],
            },
        ],
        "cables": [
            {
                "fromNode": "router_1",
                "toNode": "host_1",
                "fromInterface": "eth0",
                "toInterface": "eth0",
                "bandwidth": 1000.0,
            }
        ],
    }

    G = build_network_graph(topology_data)
    assert G.number_of_nodes() == 2
    assert G.number_of_edges() == 2  # Duplex (bidirectional) edges
    assert G.has_edge("router_1", "host_1")
    assert G.has_edge("host_1", "router_1")

    router_node = G.nodes["router_1"]
    assert router_node["type"] == "router"
    assert router_node["ospf_enabled"] is True
    assert "eth0" in router_node["interfaces"]
    assert router_node["interfaces"]["eth0"]["ip"] == "192.168.1.1/24"
    assert router_node["interfaces"]["eth0"]["vlan"] == 10

    edge_data = G.get_edge_data("router_1", "host_1")
    assert edge_data["weight"] == 1.0
    assert edge_data["bandwidth"] == 1000.0


def test_build_network_graph_missing_fields():
    topology_data = {
        "nodes": [
            {"id": "node_a"},
            {"id": "node_b"},
        ],
        "cables": [
            {"fromNode": "node_a", "toNode": "node_b"}
        ],
    }

    G = build_network_graph(topology_data)
    assert G.number_of_nodes() == 2
    assert G.number_of_edges() == 2
    assert G.nodes["node_a"]["interfaces"] == {}
    edge = G.get_edge_data("node_a", "node_b")
    assert edge["weight"] == 1.0
