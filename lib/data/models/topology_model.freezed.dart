// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topology_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Position _$PositionFromJson(Map<String, dynamic> json) {
  return _Position.fromJson(json);
}

/// @nodoc
mixin _$Position {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// Serializes this Position to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PositionCopyWith<Position> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PositionCopyWith<$Res> {
  factory $PositionCopyWith(Position value, $Res Function(Position) then) =
      _$PositionCopyWithImpl<$Res, Position>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$PositionCopyWithImpl<$Res, $Val extends Position>
    implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null}) {
    return _then(
      _value.copyWith(
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PositionImplCopyWith<$Res>
    implements $PositionCopyWith<$Res> {
  factory _$$PositionImplCopyWith(
    _$PositionImpl value,
    $Res Function(_$PositionImpl) then,
  ) = __$$PositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class __$$PositionImplCopyWithImpl<$Res>
    extends _$PositionCopyWithImpl<$Res, _$PositionImpl>
    implements _$$PositionImplCopyWith<$Res> {
  __$$PositionImplCopyWithImpl(
    _$PositionImpl _value,
    $Res Function(_$PositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null}) {
    return _then(
      _$PositionImpl(
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PositionImpl implements _Position {
  const _$PositionImpl({required this.x, required this.y});

  factory _$PositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PositionImplFromJson(json);

  @override
  final double x;
  @override
  final double y;

  @override
  String toString() {
    return 'Position(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PositionImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith =>
      __$$PositionImplCopyWithImpl<_$PositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionImplToJson(this);
  }
}

abstract class _Position implements Position {
  const factory _Position({required final double x, required final double y}) =
      _$PositionImpl;

  factory _Position.fromJson(Map<String, dynamic> json) =
      _$PositionImpl.fromJson;

  @override
  double get x;
  @override
  double get y;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InterfaceConfig _$InterfaceConfigFromJson(Map<String, dynamic> json) {
  return _InterfaceConfig.fromJson(json);
}

/// @nodoc
mixin _$InterfaceConfig {
  String get name => throw _privateConstructorUsedError;
  String? get ip => throw _privateConstructorUsedError;
  String? get subnet => throw _privateConstructorUsedError;
  String? get mac => throw _privateConstructorUsedError;
  String? get gateway => throw _privateConstructorUsedError;

  /// Serializes this InterfaceConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InterfaceConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterfaceConfigCopyWith<InterfaceConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterfaceConfigCopyWith<$Res> {
  factory $InterfaceConfigCopyWith(
    InterfaceConfig value,
    $Res Function(InterfaceConfig) then,
  ) = _$InterfaceConfigCopyWithImpl<$Res, InterfaceConfig>;
  @useResult
  $Res call({
    String name,
    String? ip,
    String? subnet,
    String? mac,
    String? gateway,
  });
}

/// @nodoc
class _$InterfaceConfigCopyWithImpl<$Res, $Val extends InterfaceConfig>
    implements $InterfaceConfigCopyWith<$Res> {
  _$InterfaceConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InterfaceConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? ip = freezed,
    Object? subnet = freezed,
    Object? mac = freezed,
    Object? gateway = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            ip: freezed == ip
                ? _value.ip
                : ip // ignore: cast_nullable_to_non_nullable
                      as String?,
            subnet: freezed == subnet
                ? _value.subnet
                : subnet // ignore: cast_nullable_to_non_nullable
                      as String?,
            mac: freezed == mac
                ? _value.mac
                : mac // ignore: cast_nullable_to_non_nullable
                      as String?,
            gateway: freezed == gateway
                ? _value.gateway
                : gateway // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InterfaceConfigImplCopyWith<$Res>
    implements $InterfaceConfigCopyWith<$Res> {
  factory _$$InterfaceConfigImplCopyWith(
    _$InterfaceConfigImpl value,
    $Res Function(_$InterfaceConfigImpl) then,
  ) = __$$InterfaceConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String? ip,
    String? subnet,
    String? mac,
    String? gateway,
  });
}

/// @nodoc
class __$$InterfaceConfigImplCopyWithImpl<$Res>
    extends _$InterfaceConfigCopyWithImpl<$Res, _$InterfaceConfigImpl>
    implements _$$InterfaceConfigImplCopyWith<$Res> {
  __$$InterfaceConfigImplCopyWithImpl(
    _$InterfaceConfigImpl _value,
    $Res Function(_$InterfaceConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InterfaceConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? ip = freezed,
    Object? subnet = freezed,
    Object? mac = freezed,
    Object? gateway = freezed,
  }) {
    return _then(
      _$InterfaceConfigImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ip: freezed == ip
            ? _value.ip
            : ip // ignore: cast_nullable_to_non_nullable
                  as String?,
        subnet: freezed == subnet
            ? _value.subnet
            : subnet // ignore: cast_nullable_to_non_nullable
                  as String?,
        mac: freezed == mac
            ? _value.mac
            : mac // ignore: cast_nullable_to_non_nullable
                  as String?,
        gateway: freezed == gateway
            ? _value.gateway
            : gateway // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InterfaceConfigImpl implements _InterfaceConfig {
  const _$InterfaceConfigImpl({
    required this.name,
    this.ip,
    this.subnet,
    this.mac,
    this.gateway,
  });

  factory _$InterfaceConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$InterfaceConfigImplFromJson(json);

  @override
  final String name;
  @override
  final String? ip;
  @override
  final String? subnet;
  @override
  final String? mac;
  @override
  final String? gateway;

  @override
  String toString() {
    return 'InterfaceConfig(name: $name, ip: $ip, subnet: $subnet, mac: $mac, gateway: $gateway)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterfaceConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.subnet, subnet) || other.subnet == subnet) &&
            (identical(other.mac, mac) || other.mac == mac) &&
            (identical(other.gateway, gateway) || other.gateway == gateway));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, ip, subnet, mac, gateway);

  /// Create a copy of InterfaceConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterfaceConfigImplCopyWith<_$InterfaceConfigImpl> get copyWith =>
      __$$InterfaceConfigImplCopyWithImpl<_$InterfaceConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InterfaceConfigImplToJson(this);
  }
}

abstract class _InterfaceConfig implements InterfaceConfig {
  const factory _InterfaceConfig({
    required final String name,
    final String? ip,
    final String? subnet,
    final String? mac,
    final String? gateway,
  }) = _$InterfaceConfigImpl;

  factory _InterfaceConfig.fromJson(Map<String, dynamic> json) =
      _$InterfaceConfigImpl.fromJson;

  @override
  String get name;
  @override
  String? get ip;
  @override
  String? get subnet;
  @override
  String? get mac;
  @override
  String? get gateway;

  /// Create a copy of InterfaceConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterfaceConfigImplCopyWith<_$InterfaceConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceNode _$DeviceNodeFromJson(Map<String, dynamic> json) {
  return _DeviceNode.fromJson(json);
}

/// @nodoc
mixin _$DeviceNode {
  String get nodeId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: DeviceType.router)
  DeviceType get type => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  Position get position => throw _privateConstructorUsedError;
  List<InterfaceConfig> get interfaces => throw _privateConstructorUsedError;

  /// Serializes this DeviceNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceNodeCopyWith<DeviceNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceNodeCopyWith<$Res> {
  factory $DeviceNodeCopyWith(
    DeviceNode value,
    $Res Function(DeviceNode) then,
  ) = _$DeviceNodeCopyWithImpl<$Res, DeviceNode>;
  @useResult
  $Res call({
    String nodeId,
    String label,
    @JsonKey(unknownEnumValue: DeviceType.router) DeviceType type,
    String model,
    Position position,
    List<InterfaceConfig> interfaces,
  });

  $PositionCopyWith<$Res> get position;
}

/// @nodoc
class _$DeviceNodeCopyWithImpl<$Res, $Val extends DeviceNode>
    implements $DeviceNodeCopyWith<$Res> {
  _$DeviceNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? label = null,
    Object? type = null,
    Object? model = null,
    Object? position = null,
    Object? interfaces = null,
  }) {
    return _then(
      _value.copyWith(
            nodeId: null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as DeviceType,
            model: null == model
                ? _value.model
                : model // ignore: cast_nullable_to_non_nullable
                      as String,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Position,
            interfaces: null == interfaces
                ? _value.interfaces
                : interfaces // ignore: cast_nullable_to_non_nullable
                      as List<InterfaceConfig>,
          )
          as $Val,
    );
  }

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionCopyWith<$Res> get position {
    return $PositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DeviceNodeImplCopyWith<$Res>
    implements $DeviceNodeCopyWith<$Res> {
  factory _$$DeviceNodeImplCopyWith(
    _$DeviceNodeImpl value,
    $Res Function(_$DeviceNodeImpl) then,
  ) = __$$DeviceNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String nodeId,
    String label,
    @JsonKey(unknownEnumValue: DeviceType.router) DeviceType type,
    String model,
    Position position,
    List<InterfaceConfig> interfaces,
  });

  @override
  $PositionCopyWith<$Res> get position;
}

/// @nodoc
class __$$DeviceNodeImplCopyWithImpl<$Res>
    extends _$DeviceNodeCopyWithImpl<$Res, _$DeviceNodeImpl>
    implements _$$DeviceNodeImplCopyWith<$Res> {
  __$$DeviceNodeImplCopyWithImpl(
    _$DeviceNodeImpl _value,
    $Res Function(_$DeviceNodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? label = null,
    Object? type = null,
    Object? model = null,
    Object? position = null,
    Object? interfaces = null,
  }) {
    return _then(
      _$DeviceNodeImpl(
        nodeId: null == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as DeviceType,
        model: null == model
            ? _value.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Position,
        interfaces: null == interfaces
            ? _value._interfaces
            : interfaces // ignore: cast_nullable_to_non_nullable
                  as List<InterfaceConfig>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceNodeImpl implements _DeviceNode {
  const _$DeviceNodeImpl({
    required this.nodeId,
    required this.label,
    @JsonKey(unknownEnumValue: DeviceType.router) required this.type,
    required this.model,
    required this.position,
    final List<InterfaceConfig> interfaces = const [],
  }) : _interfaces = interfaces;

  factory _$DeviceNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceNodeImplFromJson(json);

  @override
  final String nodeId;
  @override
  final String label;
  @override
  @JsonKey(unknownEnumValue: DeviceType.router)
  final DeviceType type;
  @override
  final String model;
  @override
  final Position position;
  final List<InterfaceConfig> _interfaces;
  @override
  @JsonKey()
  List<InterfaceConfig> get interfaces {
    if (_interfaces is EqualUnmodifiableListView) return _interfaces;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_interfaces);
  }

  @override
  String toString() {
    return 'DeviceNode(nodeId: $nodeId, label: $label, type: $type, model: $model, position: $position, interfaces: $interfaces)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceNodeImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.position, position) ||
                other.position == position) &&
            const DeepCollectionEquality().equals(
              other._interfaces,
              _interfaces,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    nodeId,
    label,
    type,
    model,
    position,
    const DeepCollectionEquality().hash(_interfaces),
  );

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceNodeImplCopyWith<_$DeviceNodeImpl> get copyWith =>
      __$$DeviceNodeImplCopyWithImpl<_$DeviceNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceNodeImplToJson(this);
  }
}

abstract class _DeviceNode implements DeviceNode {
  const factory _DeviceNode({
    required final String nodeId,
    required final String label,
    @JsonKey(unknownEnumValue: DeviceType.router)
    required final DeviceType type,
    required final String model,
    required final Position position,
    final List<InterfaceConfig> interfaces,
  }) = _$DeviceNodeImpl;

  factory _DeviceNode.fromJson(Map<String, dynamic> json) =
      _$DeviceNodeImpl.fromJson;

  @override
  String get nodeId;
  @override
  String get label;
  @override
  @JsonKey(unknownEnumValue: DeviceType.router)
  DeviceType get type;
  @override
  String get model;
  @override
  Position get position;
  @override
  List<InterfaceConfig> get interfaces;

  /// Create a copy of DeviceNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceNodeImplCopyWith<_$DeviceNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CableEdge _$CableEdgeFromJson(Map<String, dynamic> json) {
  return _CableEdge.fromJson(json);
}

/// @nodoc
mixin _$CableEdge {
  String get edgeId => throw _privateConstructorUsedError;
  String get sourceNodeId => throw _privateConstructorUsedError;
  String get sourceInterface => throw _privateConstructorUsedError;
  String get targetNodeId => throw _privateConstructorUsedError;
  String get targetInterface => throw _privateConstructorUsedError;
  String get cableType => throw _privateConstructorUsedError;

  /// Serializes this CableEdge to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CableEdge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CableEdgeCopyWith<CableEdge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CableEdgeCopyWith<$Res> {
  factory $CableEdgeCopyWith(CableEdge value, $Res Function(CableEdge) then) =
      _$CableEdgeCopyWithImpl<$Res, CableEdge>;
  @useResult
  $Res call({
    String edgeId,
    String sourceNodeId,
    String sourceInterface,
    String targetNodeId,
    String targetInterface,
    String cableType,
  });
}

/// @nodoc
class _$CableEdgeCopyWithImpl<$Res, $Val extends CableEdge>
    implements $CableEdgeCopyWith<$Res> {
  _$CableEdgeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CableEdge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? edgeId = null,
    Object? sourceNodeId = null,
    Object? sourceInterface = null,
    Object? targetNodeId = null,
    Object? targetInterface = null,
    Object? cableType = null,
  }) {
    return _then(
      _value.copyWith(
            edgeId: null == edgeId
                ? _value.edgeId
                : edgeId // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceNodeId: null == sourceNodeId
                ? _value.sourceNodeId
                : sourceNodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceInterface: null == sourceInterface
                ? _value.sourceInterface
                : sourceInterface // ignore: cast_nullable_to_non_nullable
                      as String,
            targetNodeId: null == targetNodeId
                ? _value.targetNodeId
                : targetNodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            targetInterface: null == targetInterface
                ? _value.targetInterface
                : targetInterface // ignore: cast_nullable_to_non_nullable
                      as String,
            cableType: null == cableType
                ? _value.cableType
                : cableType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CableEdgeImplCopyWith<$Res>
    implements $CableEdgeCopyWith<$Res> {
  factory _$$CableEdgeImplCopyWith(
    _$CableEdgeImpl value,
    $Res Function(_$CableEdgeImpl) then,
  ) = __$$CableEdgeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String edgeId,
    String sourceNodeId,
    String sourceInterface,
    String targetNodeId,
    String targetInterface,
    String cableType,
  });
}

/// @nodoc
class __$$CableEdgeImplCopyWithImpl<$Res>
    extends _$CableEdgeCopyWithImpl<$Res, _$CableEdgeImpl>
    implements _$$CableEdgeImplCopyWith<$Res> {
  __$$CableEdgeImplCopyWithImpl(
    _$CableEdgeImpl _value,
    $Res Function(_$CableEdgeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CableEdge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? edgeId = null,
    Object? sourceNodeId = null,
    Object? sourceInterface = null,
    Object? targetNodeId = null,
    Object? targetInterface = null,
    Object? cableType = null,
  }) {
    return _then(
      _$CableEdgeImpl(
        edgeId: null == edgeId
            ? _value.edgeId
            : edgeId // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceNodeId: null == sourceNodeId
            ? _value.sourceNodeId
            : sourceNodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceInterface: null == sourceInterface
            ? _value.sourceInterface
            : sourceInterface // ignore: cast_nullable_to_non_nullable
                  as String,
        targetNodeId: null == targetNodeId
            ? _value.targetNodeId
            : targetNodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        targetInterface: null == targetInterface
            ? _value.targetInterface
            : targetInterface // ignore: cast_nullable_to_non_nullable
                  as String,
        cableType: null == cableType
            ? _value.cableType
            : cableType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CableEdgeImpl implements _CableEdge {
  const _$CableEdgeImpl({
    required this.edgeId,
    required this.sourceNodeId,
    required this.sourceInterface,
    required this.targetNodeId,
    required this.targetInterface,
    required this.cableType,
  });

  factory _$CableEdgeImpl.fromJson(Map<String, dynamic> json) =>
      _$$CableEdgeImplFromJson(json);

  @override
  final String edgeId;
  @override
  final String sourceNodeId;
  @override
  final String sourceInterface;
  @override
  final String targetNodeId;
  @override
  final String targetInterface;
  @override
  final String cableType;

  @override
  String toString() {
    return 'CableEdge(edgeId: $edgeId, sourceNodeId: $sourceNodeId, sourceInterface: $sourceInterface, targetNodeId: $targetNodeId, targetInterface: $targetInterface, cableType: $cableType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CableEdgeImpl &&
            (identical(other.edgeId, edgeId) || other.edgeId == edgeId) &&
            (identical(other.sourceNodeId, sourceNodeId) ||
                other.sourceNodeId == sourceNodeId) &&
            (identical(other.sourceInterface, sourceInterface) ||
                other.sourceInterface == sourceInterface) &&
            (identical(other.targetNodeId, targetNodeId) ||
                other.targetNodeId == targetNodeId) &&
            (identical(other.targetInterface, targetInterface) ||
                other.targetInterface == targetInterface) &&
            (identical(other.cableType, cableType) ||
                other.cableType == cableType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    edgeId,
    sourceNodeId,
    sourceInterface,
    targetNodeId,
    targetInterface,
    cableType,
  );

  /// Create a copy of CableEdge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CableEdgeImplCopyWith<_$CableEdgeImpl> get copyWith =>
      __$$CableEdgeImplCopyWithImpl<_$CableEdgeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CableEdgeImplToJson(this);
  }
}

abstract class _CableEdge implements CableEdge {
  const factory _CableEdge({
    required final String edgeId,
    required final String sourceNodeId,
    required final String sourceInterface,
    required final String targetNodeId,
    required final String targetInterface,
    required final String cableType,
  }) = _$CableEdgeImpl;

  factory _CableEdge.fromJson(Map<String, dynamic> json) =
      _$CableEdgeImpl.fromJson;

  @override
  String get edgeId;
  @override
  String get sourceNodeId;
  @override
  String get sourceInterface;
  @override
  String get targetNodeId;
  @override
  String get targetInterface;
  @override
  String get cableType;

  /// Create a copy of CableEdge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CableEdgeImplCopyWith<_$CableEdgeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TopologyModel _$TopologyModelFromJson(Map<String, dynamic> json) {
  return _TopologyModel.fromJson(json);
}

/// @nodoc
mixin _$TopologyModel {
  String get topologyId => throw _privateConstructorUsedError;
  String get ownerUid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isTemplate => throw _privateConstructorUsedError;
  List<DeviceNode> get nodes => throw _privateConstructorUsedError;
  List<CableEdge> get edges => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TopologyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TopologyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TopologyModelCopyWith<TopologyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TopologyModelCopyWith<$Res> {
  factory $TopologyModelCopyWith(
    TopologyModel value,
    $Res Function(TopologyModel) then,
  ) = _$TopologyModelCopyWithImpl<$Res, TopologyModel>;
  @useResult
  $Res call({
    String topologyId,
    String ownerUid,
    String name,
    bool isTemplate,
    List<DeviceNode> nodes,
    List<CableEdge> edges,
    int version,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$TopologyModelCopyWithImpl<$Res, $Val extends TopologyModel>
    implements $TopologyModelCopyWith<$Res> {
  _$TopologyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TopologyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topologyId = null,
    Object? ownerUid = null,
    Object? name = null,
    Object? isTemplate = null,
    Object? nodes = null,
    Object? edges = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            topologyId: null == topologyId
                ? _value.topologyId
                : topologyId // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerUid: null == ownerUid
                ? _value.ownerUid
                : ownerUid // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            isTemplate: null == isTemplate
                ? _value.isTemplate
                : isTemplate // ignore: cast_nullable_to_non_nullable
                      as bool,
            nodes: null == nodes
                ? _value.nodes
                : nodes // ignore: cast_nullable_to_non_nullable
                      as List<DeviceNode>,
            edges: null == edges
                ? _value.edges
                : edges // ignore: cast_nullable_to_non_nullable
                      as List<CableEdge>,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TopologyModelImplCopyWith<$Res>
    implements $TopologyModelCopyWith<$Res> {
  factory _$$TopologyModelImplCopyWith(
    _$TopologyModelImpl value,
    $Res Function(_$TopologyModelImpl) then,
  ) = __$$TopologyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String topologyId,
    String ownerUid,
    String name,
    bool isTemplate,
    List<DeviceNode> nodes,
    List<CableEdge> edges,
    int version,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$TopologyModelImplCopyWithImpl<$Res>
    extends _$TopologyModelCopyWithImpl<$Res, _$TopologyModelImpl>
    implements _$$TopologyModelImplCopyWith<$Res> {
  __$$TopologyModelImplCopyWithImpl(
    _$TopologyModelImpl _value,
    $Res Function(_$TopologyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TopologyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topologyId = null,
    Object? ownerUid = null,
    Object? name = null,
    Object? isTemplate = null,
    Object? nodes = null,
    Object? edges = null,
    Object? version = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TopologyModelImpl(
        topologyId: null == topologyId
            ? _value.topologyId
            : topologyId // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerUid: null == ownerUid
            ? _value.ownerUid
            : ownerUid // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isTemplate: null == isTemplate
            ? _value.isTemplate
            : isTemplate // ignore: cast_nullable_to_non_nullable
                  as bool,
        nodes: null == nodes
            ? _value._nodes
            : nodes // ignore: cast_nullable_to_non_nullable
                  as List<DeviceNode>,
        edges: null == edges
            ? _value._edges
            : edges // ignore: cast_nullable_to_non_nullable
                  as List<CableEdge>,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TopologyModelImpl implements _TopologyModel {
  const _$TopologyModelImpl({
    required this.topologyId,
    required this.ownerUid,
    required this.name,
    this.isTemplate = false,
    final List<DeviceNode> nodes = const [],
    final List<CableEdge> edges = const [],
    this.version = 1,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
  }) : _nodes = nodes,
       _edges = edges;

  factory _$TopologyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TopologyModelImplFromJson(json);

  @override
  final String topologyId;
  @override
  final String ownerUid;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isTemplate;
  final List<DeviceNode> _nodes;
  @override
  @JsonKey()
  List<DeviceNode> get nodes {
    if (_nodes is EqualUnmodifiableListView) return _nodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodes);
  }

  final List<CableEdge> _edges;
  @override
  @JsonKey()
  List<CableEdge> get edges {
    if (_edges is EqualUnmodifiableListView) return _edges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_edges);
  }

  @override
  @JsonKey()
  final int version;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TopologyModel(topologyId: $topologyId, ownerUid: $ownerUid, name: $name, isTemplate: $isTemplate, nodes: $nodes, edges: $edges, version: $version, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TopologyModelImpl &&
            (identical(other.topologyId, topologyId) ||
                other.topologyId == topologyId) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isTemplate, isTemplate) ||
                other.isTemplate == isTemplate) &&
            const DeepCollectionEquality().equals(other._nodes, _nodes) &&
            const DeepCollectionEquality().equals(other._edges, _edges) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    topologyId,
    ownerUid,
    name,
    isTemplate,
    const DeepCollectionEquality().hash(_nodes),
    const DeepCollectionEquality().hash(_edges),
    version,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TopologyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TopologyModelImplCopyWith<_$TopologyModelImpl> get copyWith =>
      __$$TopologyModelImplCopyWithImpl<_$TopologyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TopologyModelImplToJson(this);
  }
}

abstract class _TopologyModel implements TopologyModel {
  const factory _TopologyModel({
    required final String topologyId,
    required final String ownerUid,
    required final String name,
    final bool isTemplate,
    final List<DeviceNode> nodes,
    final List<CableEdge> edges,
    final int version,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
  }) = _$TopologyModelImpl;

  factory _TopologyModel.fromJson(Map<String, dynamic> json) =
      _$TopologyModelImpl.fromJson;

  @override
  String get topologyId;
  @override
  String get ownerUid;
  @override
  String get name;
  @override
  bool get isTemplate;
  @override
  List<DeviceNode> get nodes;
  @override
  List<CableEdge> get edges;
  @override
  int get version;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of TopologyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TopologyModelImplCopyWith<_$TopologyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
