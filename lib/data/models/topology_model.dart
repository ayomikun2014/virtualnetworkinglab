import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'topology_model.freezed.dart';
part 'topology_model.g.dart';

/// Canvas Position Coordinates
@freezed
class Position with _$Position {
  const factory Position({
    required double x,
    required double y,
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
}

/// Interface Network Port Configuration
@freezed
class InterfaceConfig with _$InterfaceConfig {
  const factory InterfaceConfig({
    required String name,
    String? ip,
    String? subnet,
    String? mac,
    String? gateway,
  }) = _InterfaceConfig;

  factory InterfaceConfig.fromJson(Map<String, dynamic> json) => _$InterfaceConfigFromJson(json);
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
  }) = _DeviceNode;

  factory DeviceNode.fromJson(Map<String, dynamic> json) => _$DeviceNodeFromJson(json);
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

  factory CableEdge.fromJson(Map<String, dynamic> json) => _$CableEdgeFromJson(json);
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

  factory TopologyModel.fromJson(Map<String, dynamic> json) => _$TopologyModelFromJson(json);
}
