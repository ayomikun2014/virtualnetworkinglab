"""
Regression tests for the client/engine edge-schema contract.

Background
----------
The Flutter client serialises cable edges as:

    {"edgeId", "sourceNodeId", "sourceInterface",
     "targetNodeId", "targetInterface", "cableType"}

`graph_parser.build_network_graph` originally only looked for
`fromNode`/`source`/`sourceNode`, so every single edge produced by the real
app was silently dropped. The graph came out with the right number of NODES
and ZERO edges, and every ping therefore returned NO_PHYSICAL_ROUTE.

The old tests missed it because they hand-wrote `fromNode` fixtures, i.e. they
tested the parser against a payload the app never actually sends.

These tests feed the REAL client payload and assert on edge counts.
"""

import networkx as nx
import pytest

from app.core.graph_parser import build_network_graph
from tests.fixtures.flutter_payloads import (
    firewall_blocking_host,
    flutter_edge,
    flutter_interface,
    flutter_node,
    flutter_topology,
    three_pcs_through_switch,
    two_pcs_same_subnet,
    two_routers_ospf,
    two_subnets_with_router,
)


def test_real_flutter_payload_produces_edges():
    """THE regression test: a real client payload must yield real edges."""
    G = build_network_graph(two_pcs_same_subnet())

    assert G.number_of_nodes() == 2
    # One cable -> two directed edges (duplex).
    assert G.number_of_edges() == 2, (
        "Edges from the real Flutter payload were dropped. The parser is not "
        "reading sourceNodeId/targetNodeId."
    )
    assert G.has_edge("PC_1", "PC_2")
    assert G.has_edge("PC_2", "PC_1")


def test_real_flutter_payload_preserves_interface_names():
    """sourceInterface/targetInterface must survive onto the edge."""
    G = build_network_graph(two_subnets_with_router())

    fwd = G.get_edge_data("PC_1", "ROUTER_1")
    assert fwd["from_interface"] == "eth0"
    assert fwd["to_interface"] == "eth0"

    # The reverse edge must have the interfaces swapped.
    rev = G.get_edge_data("ROUTER_1", "PC_1")
    assert rev["from_interface"] == "eth0"
    assert rev["to_interface"] == "eth0"

    r_to_pc2 = G.get_edge_data("ROUTER_1", "PC_2")
    assert r_to_pc2["from_interface"] == "eth1"
    assert r_to_pc2["to_interface"] == "eth0"


def test_real_flutter_payload_node_identity_and_label():
    """`nodeId` is the graph key and `label` becomes the display name."""
    G = build_network_graph(two_pcs_same_subnet())

    assert set(G.nodes) == {"PC_1", "PC_2"}
    assert G.nodes["PC_1"]["name"] == "PC1"
    assert G.nodes["PC_1"]["type"] == "pc"


def test_real_flutter_payload_interfaces_are_keyed_by_name():
    """Client interfaces are a list keyed by `name`, not `id`."""
    G = build_network_graph(two_subnets_with_router())

    router_ifaces = G.nodes["ROUTER_1"]["interfaces"]
    assert set(router_ifaces) == {"eth0", "eth1"}
    assert router_ifaces["eth0"]["ip"] == "192.168.1.1"
    assert router_ifaces["eth0"]["subnet"] == "255.255.255.0"
    assert router_ifaces["eth1"]["ip"] == "10.0.0.1"

    pc_iface = G.nodes["PC_1"]["interfaces"]["eth0"]
    assert pc_iface["gateway"] == "192.168.1.1"
    assert pc_iface["status"] == "up"


def test_real_flutter_payload_multi_edge_switch_topology():
    """Three cables through a switch -> six directed edges."""
    G = build_network_graph(three_pcs_through_switch())

    assert G.number_of_nodes() == 4
    assert G.number_of_edges() == 6
    for pc in ("PC_1", "PC_2", "PC_3"):
        assert G.has_edge(pc, "SWITCH_1")
        assert G.has_edge("SWITCH_1", pc)
    # PCs are NOT directly cabled to each other.
    assert not G.has_edge("PC_1", "PC_2")


def test_real_flutter_payload_carries_acls():
    """Firewall ACL rules must reach the graph so the tracer can enforce them."""
    G = build_network_graph(firewall_blocking_host())

    acls = G.nodes["FIREWALL_1"]["interfaces"]["eth0"]["acls"]
    assert len(acls) == 1
    assert acls[0]["action"] == "deny"
    assert acls[0]["src"] == "192.168.1.10"


def test_real_flutter_payload_carries_ospf_flag():
    """`ospfEnabled` (camelCase, from Dart) must map onto `ospf_enabled`."""
    G = build_network_graph(two_routers_ospf())

    assert G.nodes["ROUTER_1"]["ospf_enabled"] is True
    assert G.nodes["ROUTER_2"]["ospf_enabled"] is True
    assert G.nodes["PC_1"]["ospf_enabled"] is False


def test_real_flutter_payload_carries_vlan():
    from tests.fixtures.flutter_payloads import two_vlans_on_one_switch

    G = build_network_graph(two_vlans_on_one_switch())
    assert G.nodes["PC_1"]["interfaces"]["eth0"]["vlan"] == 10
    assert G.nodes["PC_2"]["interfaces"]["eth0"]["vlan"] == 20


def test_cable_type_is_preserved():
    G = build_network_graph(two_routers_ospf())
    assert G.get_edge_data("ROUTER_1", "ROUTER_2")["cableType"] == "serial"
    assert G.get_edge_data("PC_1", "ROUTER_1")["cableType"] == "ethernet"


@pytest.mark.parametrize(
    "src_key,dst_key",
    [
        ("fromNode", "toNode"),          # legacy fixture spelling
        ("sourceNodeId", "targetNodeId"),  # real Flutter spelling
        ("source", "target"),            # generic graph spelling
        ("sourceNode", "targetNode"),
    ],
)
def test_all_edge_key_aliases_are_accepted(src_key, dst_key):
    """Every supported spelling must produce the same graph.

    This is the guard rail: if someone renames a key on either side of the
    wire, one of these parametrised cases fails loudly.
    """
    topology = {
        "nodes": [
            flutter_node("A", "A", "pc"),
            flutter_node("B", "B", "pc"),
        ],
        "edges": [{src_key: "A", dst_key: "B"}],
    }

    G = build_network_graph(topology)
    assert G.number_of_edges() == 2
    assert G.has_edge("A", "B")
    assert G.has_edge("B", "A")


@pytest.mark.parametrize("container_key", ["edges", "cables", "links"])
def test_edge_container_key_aliases(container_key):
    """The client sends `edges`; older payloads use `cables`/`links`."""
    topology = {
        "nodes": [flutter_node("A", "A", "pc"), flutter_node("B", "B", "pc")],
        container_key: [flutter_edge("e1", "A", "eth0", "B", "eth0")],
    }

    G = build_network_graph(topology)
    assert G.number_of_edges() == 2


def test_edges_referencing_unknown_nodes_are_skipped():
    """A dangling edge must not invent nodes or crash the parser."""
    topology = flutter_topology(
        nodes=[flutter_node("A", "A", "pc", interfaces=[flutter_interface("eth0")])],
        edges=[flutter_edge("e1", "A", "eth0", "GHOST", "eth0")],
    )

    G = build_network_graph(topology)
    assert G.number_of_nodes() == 1
    assert G.number_of_edges() == 0


def test_empty_topology_is_safe():
    G = build_network_graph(flutter_topology(nodes=[], edges=[]))
    assert isinstance(G, nx.DiGraph)
    assert G.number_of_nodes() == 0
    assert G.number_of_edges() == 0
