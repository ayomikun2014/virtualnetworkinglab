import time
import ipaddress
import networkx as nx
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, ICMP


def _get_primary_ip(G: nx.DiGraph, node_id: str, fallback_ip: str) -> str:
    node_data = G.nodes.get(node_id, {})
    interfaces = node_data.get("interfaces", {})
    if isinstance(interfaces, dict):
        for iface in interfaces.values():
            if isinstance(iface, dict):
                ip = iface.get("ip")
                if ip:
                    try:
                        ipaddress.ip_address(str(ip).split("/")[0])
                        return str(ip).split("/")[0]
                    except ValueError:
                        continue
    return fallback_ip


def _check_acl_drop(acls: list, src_ip: str, dst_ip: str, proto: str = "icmp") -> bool:
    """
    Evaluates ACL rules. Returns True if packet should be dropped.
    ACL format example: {"action": "deny", "protocol": "icmp", "src": "any", "dst": "192.168.1.0/24"}
    """
    if not isinstance(acls, list):
        return False

    for acl in acls:
        if not isinstance(acl, dict):
            continue
        action = str(acl.get("action", "allow")).lower()
        protocol = str(acl.get("protocol", "any")).lower()
        if protocol not in ("any", proto.lower()):
            continue

        rule_src = str(acl.get("src", "any"))
        rule_dst = str(acl.get("dst", "any"))

        src_match = rule_src == "any" or rule_src == src_ip
        dst_match = rule_dst == "any" or rule_dst == dst_ip

        if src_match and dst_match:
            if action in ("deny", "drop", "block"):
                return True
            elif action in ("allow", "permit"):
                return False
    return False


def simulate_icmp_ping(G: nx.DiGraph, source_node: str, target_node: str) -> dict:
    """
    Simulates an ICMP echo request/reply ping between source_node and target_node using Scapy.
    Evaluates interface status and ACL rules hop-by-hop.
    Returns path trace, packet animation frames, and RTT summary.
    """
    if not G.has_node(source_node) or not G.has_node(target_node):
        return {
            "success": False,
            "source": source_node,
            "target": target_node,
            "path": [],
            "packet_stream": [],
            "total_rtt_ms": 0.0,
            "drop_reason": "NO_PHYSICAL_ROUTE",
            "message": f"Node '{source_node}' or '{target_node}' does not exist in graph.",
        }

    src_ip = _get_primary_ip(G, source_node, "192.168.1.10")
    dst_ip = _get_primary_ip(G, target_node, "192.168.1.20")

    # Synthesize Scapy ICMP Echo Request Packet in unprivileged memory space
    scapy_pkt = Ether() / IP(src=src_ip, dst=dst_ip) / ICMP(type=8, code=0)
    pkt_summary = scapy_pkt.summary()

    try:
        path = nx.shortest_path(G, source=source_node, target=target_node, weight="weight")
    except (nx.NetworkXNoPath, nx.NodeNotFound):
        return {
            "success": False,
            "source": source_node,
            "target": target_node,
            "path": [],
            "packet_stream": [],
            "total_rtt_ms": 0.0,
            "drop_reason": "NO_PHYSICAL_ROUTE",
            "message": f"No physical or logical path found between '{source_node}' and '{target_node}'.",
        }

    packet_stream = []
    current_time_ms = 0.0
    frame_index = 0
    packet_dropped = False
    drop_reason = None

    for i in range(len(path) - 1):
        u, v = path[i], path[i + 1]
        edge_data = G.get_edge_data(u, v) or {}
        bandwidth = edge_data.get("bandwidth", 1000.0)
        hop_latency_ms = round(10.0 + (1000.0 / max(bandwidth, 1.0)), 2)
        current_time_ms += hop_latency_ms

        from_iface_name = edge_data.get("from_interface", "")
        u_ifaces = G.nodes[u].get("interfaces", {})
        from_iface_data = u_ifaces.get(from_iface_name, {}) if isinstance(u_ifaces, dict) else {}

        if isinstance(from_iface_data, dict):
            # Check interface operational status
            if from_iface_data.get("status") == "down":
                packet_dropped = True
                drop_reason = f"Interface '{from_iface_name}' on node '{u}' is administratively down."

            # Check ACL rules
            if not packet_dropped and _check_acl_drop(from_iface_data.get("acls", []), src_ip, dst_ip):
                packet_dropped = True
                drop_reason = f"Packet dropped by ACL on node '{u}' interface '{from_iface_name}'."

        frame_status = "dropped" if packet_dropped else "forwarded"

        packet_stream.append({
            "frameIndex": frame_index,
            "fromNode": u,
            "toNode": v,
            "fromInterface": from_iface_name,
            "toInterface": edge_data.get("to_interface", ""),
            "timestampMs": round(current_time_ms, 2),
            "status": frame_status,
            "dropReason": drop_reason,
            "packet": {
                "summary": pkt_summary,
                "srcIp": src_ip,
                "dstIp": dst_ip,
                "protocol": "ICMP",
                "type": "Echo Request",
            },
        })
        frame_index += 1

        if packet_dropped:
            break

    total_rtt_ms = round(current_time_ms * 2.0, 2) if not packet_dropped else 0.0
    success = not packet_dropped

    return {
        "success": success,
        "source": source_node,
        "target": target_node,
        "path": path,
        "packet_stream": packet_stream,
        "total_rtt_ms": total_rtt_ms,
        "drop_reason": drop_reason,
        "message": "Ping successful" if success else (drop_reason or "Ping failed"),
    }

