"""
REAL Flutter client payloads.

Everything in this module is byte-for-byte what `TopologyModel.toJson()` in
`lib/data/models/topology_model.dart` actually emits (verified against
`topology_model.g.dart`). Do NOT "tidy" the key names to match the parser —
the whole point of these fixtures is to catch the class of bug where the
engine and the client disagree about the wire format.

Key facts about the real client format:
  * nodes use  `nodeId`  and `label`   (not `id` / `name`)
  * edges use  `sourceNodeId` / `targetNodeId`
  * edges use  `sourceInterface` / `targetInterface`
  * edges live under the `edges` key    (not `cables` / `links`)
  * interfaces are a LIST of objects keyed by `name`
  * device `type` is the lowercase JsonValue: router|switch|firewall|pc|server|cloud
"""

from typing import Any, Dict, List, Optional


def flutter_interface(
    name: str,
    ip: Optional[str] = None,
    subnet: Optional[str] = None,
    gateway: Optional[str] = None,
    mac: Optional[str] = None,
    status: str = "up",
    vlan: Optional[int] = None,
    acls: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """One entry of DeviceNode.interfaces as the Dart client serialises it."""
    iface: Dict[str, Any] = {"name": name, "status": status}
    if ip is not None:
        iface["ip"] = ip
    if subnet is not None:
        iface["subnet"] = subnet
    if gateway is not None:
        iface["gateway"] = gateway
    if mac is not None:
        iface["mac"] = mac
    if vlan is not None:
        iface["vlan"] = vlan
    if acls is not None:
        iface["acls"] = acls
    return iface


def flutter_node(
    node_id: str,
    label: str,
    device_type: str,
    x: float = 0.0,
    y: float = 0.0,
    interfaces: Optional[List[Dict[str, Any]]] = None,
    model: str = "standard",
    ospf_enabled: bool = False,
) -> Dict[str, Any]:
    """A DeviceNode exactly as the Dart client serialises it."""
    return {
        "nodeId": node_id,
        "label": label,
        "type": device_type,
        "model": model,
        "position": {"x": x, "y": y},
        "interfaces": interfaces if interfaces is not None else [],
        "ospfEnabled": ospf_enabled,
    }


def flutter_edge(
    edge_id: str,
    source_node_id: str,
    source_interface: str,
    target_node_id: str,
    target_interface: str,
    cable_type: str = "ethernet",
) -> Dict[str, Any]:
    """A CableEdge exactly as the Dart client serialises it."""
    return {
        "edgeId": edge_id,
        "sourceNodeId": source_node_id,
        "sourceInterface": source_interface,
        "targetNodeId": target_node_id,
        "targetInterface": target_interface,
        "cableType": cable_type,
    }


def flutter_topology(
    nodes: List[Dict[str, Any]],
    edges: List[Dict[str, Any]],
    topology_id: str = "topo_test_1",
    owner_uid: str = "uid_student_1",
    name: str = "Test Topology",
) -> Dict[str, Any]:
    """A whole TopologyModel document as the Dart client serialises it."""
    return {
        "topologyId": topology_id,
        "ownerUid": owner_uid,
        "name": name,
        "isTemplate": False,
        "nodes": nodes,
        "edges": edges,
        "version": 1,
    }


# ---------------------------------------------------------------------------
# Ready-made scenarios
# ---------------------------------------------------------------------------

def two_pcs_same_subnet() -> Dict[str, Any]:
    """PC1 --- PC2, both 192.168.1.0/24. A ping between them should succeed."""
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface("eth0", ip="192.168.1.10", subnet="255.255.255.0")],
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 400, 100,
                [flutter_interface("eth0", ip="192.168.1.20", subnet="255.255.255.0")],
            ),
        ],
        edges=[flutter_edge("edge_1", "PC_1", "eth0", "PC_2", "eth0")],
    )


def two_pcs_different_subnets() -> Dict[str, Any]:
    """PC1 --- PC2 but on 192.168.1.0/24 and 10.0.0.0/24, with no router.

    Physically cabled, logically unreachable. This is the Topic 3 / L2 lesson:
    the correct answer is that the ping FAILS.
    """
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface("eth0", ip="192.168.1.10", subnet="255.255.255.0")],
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 400, 100,
                [flutter_interface("eth0", ip="10.0.0.20", subnet="255.255.255.0")],
            ),
        ],
        edges=[flutter_edge("edge_1", "PC_1", "eth0", "PC_2", "eth0")],
    )


def three_pcs_through_switch() -> Dict[str, Any]:
    """PC1, PC2, PC3 all hanging off SW1 in one subnet."""
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface("eth0", ip="192.168.1.10", subnet="255.255.255.0")],
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 400, 100,
                [flutter_interface("eth0", ip="192.168.1.20", subnet="255.255.255.0")],
            ),
            flutter_node(
                "PC_3", "PC3", "pc", 700, 100,
                [flutter_interface("eth0", ip="192.168.1.30", subnet="255.255.255.0")],
            ),
            flutter_node(
                "SWITCH_1", "SW1", "switch", 400, 400,
                [
                    flutter_interface("eth0"),
                    flutter_interface("eth1"),
                    flutter_interface("eth2"),
                ],
            ),
        ],
        edges=[
            flutter_edge("edge_1", "PC_1", "eth0", "SWITCH_1", "eth0"),
            flutter_edge("edge_2", "PC_2", "eth0", "SWITCH_1", "eth1"),
            flutter_edge("edge_3", "PC_3", "eth0", "SWITCH_1", "eth2"),
        ],
    )


def two_vlans_on_one_switch() -> Dict[str, Any]:
    """PC1 in VLAN 10, PC2 in VLAN 20, same switch, same subnet.

    Topic 4 / L2: they must NOT reach each other despite the cabling.
    """
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface("eth0", ip="192.168.1.10", subnet="255.255.255.0", vlan=10)],
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 400, 100,
                [flutter_interface("eth0", ip="192.168.1.20", subnet="255.255.255.0", vlan=20)],
            ),
            flutter_node(
                "SWITCH_1", "SW1", "switch", 250, 400,
                [
                    flutter_interface("eth0", vlan=10),
                    flutter_interface("eth1", vlan=20),
                ],
            ),
        ],
        edges=[
            flutter_edge("edge_1", "PC_1", "eth0", "SWITCH_1", "eth0"),
            flutter_edge("edge_2", "PC_2", "eth0", "SWITCH_1", "eth1"),
        ],
    )


def two_subnets_with_router() -> Dict[str, Any]:
    """PC1 (192.168.1.0/24) -- R1 -- PC2 (10.0.0.0/24), gateways set."""
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface(
                    "eth0", ip="192.168.1.10", subnet="255.255.255.0",
                    gateway="192.168.1.1",
                )],
            ),
            flutter_node(
                "ROUTER_1", "R1", "router", 400, 100,
                [
                    flutter_interface("eth0", ip="192.168.1.1", subnet="255.255.255.0"),
                    flutter_interface("eth1", ip="10.0.0.1", subnet="255.255.255.0"),
                ],
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 700, 100,
                [flutter_interface(
                    "eth0", ip="10.0.0.20", subnet="255.255.255.0",
                    gateway="10.0.0.1",
                )],
            ),
        ],
        edges=[
            flutter_edge("edge_1", "PC_1", "eth0", "ROUTER_1", "eth0"),
            flutter_edge("edge_2", "ROUTER_1", "eth1", "PC_2", "eth0"),
        ],
    )


def firewall_blocking_host() -> Dict[str, Any]:
    """PC1 -- FW1 -- SERVER1, with an ACL on the firewall denying PC1."""
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface(
                    "eth0", ip="192.168.1.10", subnet="255.255.255.0",
                    gateway="192.168.1.1",
                )],
            ),
            flutter_node(
                "FIREWALL_1", "FW1", "firewall", 400, 100,
                [
                    flutter_interface(
                        "eth0", ip="192.168.1.1", subnet="255.255.255.0",
                        acls=[{
                            "action": "deny",
                            "protocol": "icmp",
                            "src": "192.168.1.10",
                            "dst": "192.168.1.50",
                        }],
                    ),
                    flutter_interface("eth1", ip="192.168.1.2", subnet="255.255.255.0"),
                ],
            ),
            flutter_node(
                "SERVER_1", "Server1", "server", 700, 100,
                [flutter_interface(
                    "eth0", ip="192.168.1.50", subnet="255.255.255.0",
                    gateway="192.168.1.2",
                )],
            ),
        ],
        edges=[
            flutter_edge("edge_1", "PC_1", "eth0", "FIREWALL_1", "eth0"),
            flutter_edge("edge_2", "FIREWALL_1", "eth1", "SERVER_1", "eth0"),
        ],
    )


def two_routers_ospf() -> Dict[str, Any]:
    """R1 -- R2 with OSPF enabled on both, one host behind each."""
    return flutter_topology(
        nodes=[
            flutter_node(
                "PC_1", "PC1", "pc", 100, 100,
                [flutter_interface(
                    "eth0", ip="192.168.1.10", subnet="255.255.255.0",
                    gateway="192.168.1.1",
                )],
            ),
            flutter_node(
                "ROUTER_1", "R1", "router", 350, 100,
                [
                    flutter_interface("eth0", ip="192.168.1.1", subnet="255.255.255.0"),
                    flutter_interface("eth1", ip="172.16.0.1", subnet="255.255.255.0"),
                ],
                ospf_enabled=True,
            ),
            flutter_node(
                "ROUTER_2", "R2", "router", 600, 100,
                [
                    flutter_interface("eth0", ip="172.16.0.2", subnet="255.255.255.0"),
                    flutter_interface("eth1", ip="10.0.0.1", subnet="255.255.255.0"),
                ],
                ospf_enabled=True,
            ),
            flutter_node(
                "PC_2", "PC2", "pc", 850, 100,
                [flutter_interface(
                    "eth0", ip="10.0.0.20", subnet="255.255.255.0",
                    gateway="10.0.0.1",
                )],
            ),
        ],
        edges=[
            flutter_edge("edge_1", "PC_1", "eth0", "ROUTER_1", "eth0"),
            flutter_edge("edge_2", "ROUTER_1", "eth1", "ROUTER_2", "eth0", cable_type="serial"),
            flutter_edge("edge_3", "ROUTER_2", "eth1", "PC_2", "eth0"),
        ],
    )
