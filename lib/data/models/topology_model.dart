import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'topology_model.freezed.dart';
part 'topology_model.g.dart';

/// Canvas Position Coordinates
@freezed
class Position with _$Position {
  const factory Position({required double x, required double y}) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);
}

/// A single firewall ACL rule.
///
/// Matches the shape `packet_tracer._check_acl_drop` expects:
/// `{"action": "deny", "protocol": "icmp", "src": "any", "dst": "10.0.0.5"}`.
/// `src`/`dst` accept a literal IP or the wildcard `any`.
@freezed
class AclRule with _$AclRule {
  const factory AclRule({
    /// 'allow' | 'deny'
    @Default('deny') String action,

    /// 'any' | 'icmp' | 'tcp' | 'udp'
    @Default('any') String protocol,
    @Default('any') String src,
    @Default('any') String dst,
  }) = _AclRule;

  factory AclRule.fromJson(Map<String, dynamic> json) =>
      _$AclRuleFromJson(json);
}

/// Interface Network Port Configuration
///
/// Every field here is read by the simulation engine (`graph_parser.
/// _normalise_interface`) and by the auto-grader, so the property inspector
/// must be able to edit all of them. Before the inspector existed, IPs were
/// auto-assigned and VLAN/status/ACLs were unreachable from the UI, which meant
/// the `vlan_tagging`, `interface_status` and ACL-drop criteria could never
/// legitimately pass.
@freezed
class InterfaceConfig with _$InterfaceConfig {
  const factory InterfaceConfig({
    required String name,
    String? ip,

    /// Dotted-decimal mask, e.g. '255.255.255.0'.
    String? subnet,
    String? mac,

    /// Default gateway. Only meaningful on hosts (pc/server).
    String? gateway,

    /// 'up' | 'down'. Administrative state.
    @Default('up') String status,

    /// VLAN id, or null for an untagged port.
    int? vlan,

    /// Only meaningful on firewalls; evaluated hop-by-hop by the tracer.
    @Default(<AclRule>[]) List<AclRule> acls,
  }) = _InterfaceConfig;

  factory InterfaceConfig.fromJson(Map<String, dynamic> json) =>
      _$InterfaceConfigFromJson(json);
}

/// Canvas Network Device Node
@freezed
class DeviceNode with _$DeviceNode {
  const factory DeviceNode({
    required String nodeId,
    required String label,
    @JsonKey(unknownEnumValue: DeviceType.router) required DeviceType type,
    required String model,
    required Position position,
    @Default([]) List<InterfaceConfig> interfaces,

    /// Only meaningful on routers. Read by the `ospf_adjacency` criterion.
    @Default(false) bool ospfEnabled,
  }) = _DeviceNode;

  factory DeviceNode.fromJson(Map<String, dynamic> json) =>
      _$DeviceNodeFromJson(json);
}

/// Cable Connection Link Between Device Ports
@freezed
class CableEdge with _$CableEdge {
  const factory CableEdge({
    required String edgeId,
    required String sourceNodeId,
    required String sourceInterface,
    required String targetNodeId,
    required String targetInterface,
    required String cableType,
  }) = _CableEdge;

  factory CableEdge.fromJson(Map<String, dynamic> json) =>
      _$CableEdgeFromJson(json);
}

/// Network Topology Canvas Graph Model
@freezed
class TopologyModel with _$TopologyModel {
  const factory TopologyModel({
    required String topologyId,
    required String ownerUid,
    required String name,
    @Default(false) bool isTemplate,
    @Default([]) List<DeviceNode> nodes,
    @Default([]) List<CableEdge> edges,
    @Default(1) int version,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _TopologyModel;

  factory TopologyModel.fromJson(Map<String, dynamic> json) =>
      _$TopologyModelFromJson(json);
}
