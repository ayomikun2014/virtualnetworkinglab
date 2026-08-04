// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topology_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PositionImpl _$$PositionImplFromJson(Map<String, dynamic> json) =>
    _$PositionImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$$PositionImplToJson(_$PositionImpl instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

_$AclRuleImpl _$$AclRuleImplFromJson(Map<String, dynamic> json) =>
    _$AclRuleImpl(
      action: json['action'] as String? ?? 'deny',
      protocol: json['protocol'] as String? ?? 'any',
      src: json['src'] as String? ?? 'any',
      dst: json['dst'] as String? ?? 'any',
    );

Map<String, dynamic> _$$AclRuleImplToJson(_$AclRuleImpl instance) =>
    <String, dynamic>{
      'action': instance.action,
      'protocol': instance.protocol,
      'src': instance.src,
      'dst': instance.dst,
    };

_$InterfaceConfigImpl _$$InterfaceConfigImplFromJson(
  Map<String, dynamic> json,
) => _$InterfaceConfigImpl(
  name: json['name'] as String,
  ip: json['ip'] as String?,
  subnet: json['subnet'] as String?,
  mac: json['mac'] as String?,
  gateway: json['gateway'] as String?,
  status: json['status'] as String? ?? 'up',
  vlan: (json['vlan'] as num?)?.toInt(),
  acls:
      (json['acls'] as List<dynamic>?)
          ?.map((e) => AclRule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AclRule>[],
);

Map<String, dynamic> _$$InterfaceConfigImplToJson(
  _$InterfaceConfigImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'ip': instance.ip,
  'subnet': instance.subnet,
  'mac': instance.mac,
  'gateway': instance.gateway,
  'status': instance.status,
  'vlan': instance.vlan,
  'acls': instance.acls,
};

_$DeviceNodeImpl _$$DeviceNodeImplFromJson(Map<String, dynamic> json) =>
    _$DeviceNodeImpl(
      nodeId: json['nodeId'] as String,
      label: json['label'] as String,
      type: $enumDecode(
        _$DeviceTypeEnumMap,
        json['type'],
        unknownValue: DeviceType.router,
      ),
      model: json['model'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      interfaces:
          (json['interfaces'] as List<dynamic>?)
              ?.map((e) => InterfaceConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ospfEnabled: json['ospfEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$$DeviceNodeImplToJson(_$DeviceNodeImpl instance) =>
    <String, dynamic>{
      'nodeId': instance.nodeId,
      'label': instance.label,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'model': instance.model,
      'position': instance.position,
      'interfaces': instance.interfaces,
      'ospfEnabled': instance.ospfEnabled,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.router: 'router',
  DeviceType.switchDevice: 'switch',
  DeviceType.firewall: 'firewall',
  DeviceType.pc: 'pc',
  DeviceType.server: 'server',
  DeviceType.cloud: 'cloud',
};

_$CableEdgeImpl _$$CableEdgeImplFromJson(Map<String, dynamic> json) =>
    _$CableEdgeImpl(
      edgeId: json['edgeId'] as String,
      sourceNodeId: json['sourceNodeId'] as String,
      sourceInterface: json['sourceInterface'] as String,
      targetNodeId: json['targetNodeId'] as String,
      targetInterface: json['targetInterface'] as String,
      cableType: json['cableType'] as String,
    );

Map<String, dynamic> _$$CableEdgeImplToJson(_$CableEdgeImpl instance) =>
    <String, dynamic>{
      'edgeId': instance.edgeId,
      'sourceNodeId': instance.sourceNodeId,
      'sourceInterface': instance.sourceInterface,
      'targetNodeId': instance.targetNodeId,
      'targetInterface': instance.targetInterface,
      'cableType': instance.cableType,
    };

_$TopologyModelImpl _$$TopologyModelImplFromJson(
  Map<String, dynamic> json,
) => _$TopologyModelImpl(
  topologyId: json['topologyId'] as String,
  ownerUid: json['ownerUid'] as String,
  name: json['name'] as String,
  isTemplate: json['isTemplate'] as bool? ?? false,
  nodes:
      (json['nodes'] as List<dynamic>?)
          ?.map((e) => DeviceNode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  edges:
      (json['edges'] as List<dynamic>?)
          ?.map((e) => CableEdge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  version: (json['version'] as num?)?.toInt() ?? 1,
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$$TopologyModelImplToJson(_$TopologyModelImpl instance) =>
    <String, dynamic>{
      'topologyId': instance.topologyId,
      'ownerUid': instance.ownerUid,
      'name': instance.name,
      'isTemplate': instance.isTemplate,
      'nodes': instance.nodes,
      'edges': instance.edges,
      'version': instance.version,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
