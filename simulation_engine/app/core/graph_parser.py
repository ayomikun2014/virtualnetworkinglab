import networkx as nx
from typing import Dict, Any


def _coerce_vlan(raw: Any) -> Any:
    """VLAN ids arrive as int, str or None. Normalise to int where possible.

    Note `or` is deliberately avoided here: VLAN 0 is falsy but valid input,
    and we must not silently swallow it.
    """
    if raw is None or raw == "":
        return None
    try:
        return int(raw)
    except (ValueError, TypeError):
        return raw


def _normalise_interface(iface: Dict[str, Any]) -> Dict[str, Any]:
    """Flattens one interface into the canonical shape the engine works with.

    Accepts every key spelling we have seen on the wire:
      * the Flutter client  -> ip / subnet / gateway / mac / vlan / acls / status
      * older fixtures      -> ipAddress / subnetMask / macAddress / vlanId / aclRules

    IMPORTANT: `gateway` must be preserved. The default-gateway rules in
    packet_tracer depend on it, and without it no inter-subnet level can pass.
    """
    vlan = iface.get("vlan")
    if vlan is None:
        vlan = iface.get("vlanId")

    acls = iface.get("acls")
    if not acls:
        acls = iface.get("aclRules") or []
    if not isinstance(acls, list):
        acls = []

    status = str(iface.get("status") or "up").lower()

    return {
        "ip": iface.get("ip") or iface.get("ipAddress") or "",
        "subnet": iface.get("subnet") or iface.get("subnetMask") or "",
        "gateway": iface.get("gateway") or iface.get("defaultGateway") or "",
        "mac": iface.get("mac") or iface.get("macAddress") or "",
        "vlan": _coerce_vlan(vlan),
        "acls": acls,
        "status": status,
    }


def build_network_graph(topology_data: Dict[str, Any]) -> nx.DiGraph:
    """
    Converts network topology data (nodes, interfaces, cables) into a NetworkX DiGraph.

    Node attributes:
        - name: str
        - type: str (e.g., 'router', 'switch', 'host')
        - model: str
        - interfaces: dict mapping interface_id/name -> interface details (ip, mac, vlan, acls)

    Edge attributes:
        - cableType: str (e.g., 'ethernet', 'fiber', 'serial')
        - bandwidth: float (Mbps/Gbps)
        - from_interface: str
        - to_interface: str
        - weight: float (for path calculations, default 1.0)
    """
    G = nx.DiGraph()

    nodes_data = topology_data.get("nodes", [])
    if isinstance(nodes_data, dict):
        nodes_data = list(nodes_data.values())

    for node in nodes_data:
        if not isinstance(node, dict):
            continue

        # The Flutter client serialises nodes as `nodeId` + `label`; older test
        # fixtures use `id` + `name`. Accept every spelling.
        node_id = str(node.get("id") or node.get("nodeId") or node.get("name") or "")
        if not node_id:
            continue

        raw_interfaces = node.get("interfaces", [])
        interfaces_dict = {}

        if isinstance(raw_interfaces, list):
            for iface in raw_interfaces:
                if not isinstance(iface, dict):
                    continue
                iface_id = str(iface.get("id") or iface.get("name") or iface.get("port") or f"iface_{len(interfaces_dict)}")
                interfaces_dict[iface_id] = _normalise_interface(iface)
        elif isinstance(raw_interfaces, dict):
            for k, iface in raw_interfaces.items():
                if isinstance(iface, dict):
                    interfaces_dict[str(k)] = _normalise_interface(iface)
                else:
                    # Shorthand form: {"eth0": "192.168.1.1"}
                    interfaces_dict[str(k)] = _normalise_interface({"ip": str(iface)})

        G.add_node(
            node_id,
            name=node.get("name") or node.get("label") or node_id,
            type=str(node.get("type", "generic")).lower(),
            model=node.get("model", "standard"),
            interfaces=interfaces_dict,
            ospf_enabled=bool(node.get("ospf_enabled") or node.get("ospfEnabled", False)),
        )

    cables_data = topology_data.get("cables") or topology_data.get("links") or topology_data.get("edges") or []
    if isinstance(cables_data, dict):
        cables_data = list(cables_data.values())

    for cable in cables_data:
        if not isinstance(cable, dict):
            continue

        # ---------------------------------------------------------------
        # Edge key aliases.
        #
        # The Flutter client (see CableEdge in lib/data/models/topology_model.dart)
        # serialises edges as sourceNodeId / targetNodeId / sourceInterface /
        # targetInterface. Before this list included those keys, EVERY edge
        # produced by the real app was silently skipped, so the graph had nodes
        # but zero edges and every ping returned NO_PHYSICAL_ROUTE.
        # Regression test: tests/test_graph_parser.py::test_real_flutter_payload_*
        # ---------------------------------------------------------------
        from_node = str(
            cable.get("fromNode")
            or cable.get("sourceNodeId")
            or cable.get("source")
            or cable.get("sourceNode")
            or ""
        )
        to_node = str(
            cable.get("toNode")
            or cable.get("targetNodeId")
            or cable.get("target")
            or cable.get("targetNode")
            or ""
        )

        if not from_node or not to_node or not G.has_node(from_node) or not G.has_node(to_node):
            continue

        cable_type = cable.get("cableType") or cable.get("type") or "copper"

        raw_bw = cable.get("bandwidth")
        try:
            bandwidth = float(raw_bw) if raw_bw is not None else 1000.0
        except (ValueError, TypeError):
            bandwidth = 1000.0

        raw_cost = cable.get("cost") or cable.get("weight")
        if raw_cost is not None:
            try:
                weight = float(raw_cost)
            except (ValueError, TypeError):
                weight = 1.0
        else:
            weight = 1.0

        from_iface = str(cable.get("fromInterface") or cable.get("sourceInterface") or "")
        to_iface = str(cable.get("toInterface") or cable.get("targetInterface") or "")

        # Add bidirectional (duplex) edges
        G.add_edge(
            from_node,
            to_node,
            cableType=cable_type,
            bandwidth=bandwidth,
            weight=weight,
            from_interface=from_iface,
            to_interface=to_iface,
        )
        G.add_edge(
            to_node,
            from_node,
            cableType=cable_type,
            bandwidth=bandwidth,
            weight=weight,
            from_interface=to_iface,
            to_interface=from_iface,
        )

    return G

