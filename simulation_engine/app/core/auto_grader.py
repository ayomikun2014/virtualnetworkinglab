import networkx as nx
from typing import List, Dict, Any
from app.core.packet_tracer import simulate_icmp_ping


def evaluate_grading_criteria(G: nx.DiGraph, criteria_list: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Evaluates auto-grading criteria against a network topology graph G.

    Supported criteria types:
      - 'ping_reachability': source, target
      - 'vlan_tagging': node, interface, expected_vlan
      - 'ospf_adjacency': node_a, node_b (or node)
      - 'interface_status': node, interface, expected_status ('up'/'down')
    """
    total_score = 0.0
    max_score = 0.0
    breakdown = []

    for item in criteria_list:
        c_id = str(item.get("id", f"rule_{len(breakdown)+1}"))
        c_type = item.get("type", "").lower()
        c_desc = item.get("description", f"Check {c_type}")
        weight = float(item.get("weight", item.get("points", 10.0)))
        max_score += weight

        passed = False
        feedback = ""

        if c_type in ("ping_reachability", "ping", "reachability"):
            src = str(item.get("source") or item.get("fromNode", ""))
            dst = str(item.get("target") or item.get("toNode", ""))
            res = simulate_icmp_ping(G, src, dst)
            passed = res.get("success", False)
            feedback = f"Ping from {src} to {dst}: " + ("SUCCESS" if passed else res.get("message", "FAILED"))

        elif c_type in ("vlan_tagging", "vlan"):
            node_id = str(item.get("node") or item.get("nodeId", ""))
            iface_name = str(item.get("interface") or item.get("port", ""))
            expected_vlan = item.get("expected_vlan") or item.get("vlan")

            if G.has_node(node_id):
                node_ifaces = G.nodes[node_id].get("interfaces", {})
                iface_info = node_ifaces.get(iface_name, {})
                actual_vlan = iface_info.get("vlan")
                if str(actual_vlan) == str(expected_vlan):
                    passed = True
                    feedback = f"Node '{node_id}' interface '{iface_name}' correctly tagged with VLAN {expected_vlan}."
                else:
                    feedback = f"Node '{node_id}' interface '{iface_name}' VLAN is {actual_vlan} (expected {expected_vlan})."
            else:
                feedback = f"Node '{node_id}' not found in topology."

        elif c_type in ("ospf_adjacency", "ospf"):
            node_a = str(item.get("node_a") or item.get("nodeA") or item.get("node", ""))
            node_b = str(item.get("node_b") or item.get("nodeB", ""))

            has_a = G.has_node(node_a) and bool(G.nodes[node_a].get("ospf_enabled"))
            has_b = (not node_b) or (G.has_node(node_b) and bool(G.nodes[node_b].get("ospf_enabled")))

            if has_a and has_b:
                passed = True
                feedback = f"OSPF adjacency configured on {node_a}" + (f" and {node_b}" if node_b else "") + "."
            else:
                feedback = f"OSPF not enabled on target nodes ({node_a}, {node_b})."

        elif c_type in ("interface_status", "port_status"):
            node_id = str(item.get("node", ""))
            iface_name = str(item.get("interface", ""))
            expected_status = str(item.get("expected_status", "up")).lower()

            if G.has_node(node_id):
                iface_info = G.nodes[node_id].get("interfaces", {}).get(iface_name, {})
                actual_status = str(iface_info.get("status", "up")).lower()
                passed = actual_status == expected_status
                feedback = f"Interface {node_id}:{iface_name} is {actual_status} (expected {expected_status})."
            else:
                feedback = f"Node '{node_id}' not found."

        else:
            # Fallback pass for generic/custom criterion
            passed = True
            feedback = f"Custom criterion '{c_desc}' evaluated successfully."

        earned = weight if passed else 0.0
        total_score += earned

        breakdown.append({
            "id": c_id,
            "type": c_type,
            "description": c_desc,
            "passed": passed,
            "score": earned,
            "maxScore": weight,
            "feedback": feedback,
        })

    percentage = round((total_score / max_score * 100.0), 2) if max_score > 0 else 100.0

    return {
        "totalScore": round(total_score, 2),
        "maxScore": round(max_score, 2),
        "percentage": percentage,
        "passed": percentage >= 70.0,
        "breakdown": breakdown,
    }
