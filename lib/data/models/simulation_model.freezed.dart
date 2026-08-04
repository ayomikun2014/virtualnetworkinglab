// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'simulation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SimulationQueueModel _$SimulationQueueModelFromJson(Map<String, dynamic> json) {
  return _SimulationQueueModel.fromJson(json);
}

/// @nodoc
mixin _$SimulationQueueModel {
  String get queueId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get topologyId => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: QueueStatus.queued)
  QueueStatus get status => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get requestedAt => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get startedAt => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String? get workerId => throw _privateConstructorUsedError;
  int get retryCount => throw _privateConstructorUsedError;

  /// Serializes this SimulationQueueModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SimulationQueueModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimulationQueueModelCopyWith<SimulationQueueModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimulationQueueModelCopyWith<$Res> {
  factory $SimulationQueueModelCopyWith(
    SimulationQueueModel value,
    $Res Function(SimulationQueueModel) then,
  ) = _$SimulationQueueModelCopyWithImpl<$Res, SimulationQueueModel>;
  @useResult
  $Res call({
    String queueId,
    String userId,
    String topologyId,
    @JsonKey(unknownEnumValue: QueueStatus.queued) QueueStatus status,
    int priority,
    @TimestampConverter() DateTime requestedAt,
    @NullableTimestampConverter() DateTime? startedAt,
    @NullableTimestampConverter() DateTime? completedAt,
    String? workerId,
    int retryCount,
  });
}

/// @nodoc
class _$SimulationQueueModelCopyWithImpl<
  $Res,
  $Val extends SimulationQueueModel
>
    implements $SimulationQueueModelCopyWith<$Res> {
  _$SimulationQueueModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SimulationQueueModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queueId = null,
    Object? userId = null,
    Object? topologyId = null,
    Object? status = null,
    Object? priority = null,
    Object? requestedAt = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? workerId = freezed,
    Object? retryCount = null,
  }) {
    return _then(
      _value.copyWith(
            queueId: null == queueId
                ? _value.queueId
                : queueId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            topologyId: null == topologyId
                ? _value.topologyId
                : topologyId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as QueueStatus,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            requestedAt: null == requestedAt
                ? _value.requestedAt
                : requestedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            workerId: freezed == workerId
                ? _value.workerId
                : workerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            retryCount: null == retryCount
                ? _value.retryCount
                : retryCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SimulationQueueModelImplCopyWith<$Res>
    implements $SimulationQueueModelCopyWith<$Res> {
  factory _$$SimulationQueueModelImplCopyWith(
    _$SimulationQueueModelImpl value,
    $Res Function(_$SimulationQueueModelImpl) then,
  ) = __$$SimulationQueueModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String queueId,
    String userId,
    String topologyId,
    @JsonKey(unknownEnumValue: QueueStatus.queued) QueueStatus status,
    int priority,
    @TimestampConverter() DateTime requestedAt,
    @NullableTimestampConverter() DateTime? startedAt,
    @NullableTimestampConverter() DateTime? completedAt,
    String? workerId,
    int retryCount,
  });
}

/// @nodoc
class __$$SimulationQueueModelImplCopyWithImpl<$Res>
    extends _$SimulationQueueModelCopyWithImpl<$Res, _$SimulationQueueModelImpl>
    implements _$$SimulationQueueModelImplCopyWith<$Res> {
  __$$SimulationQueueModelImplCopyWithImpl(
    _$SimulationQueueModelImpl _value,
    $Res Function(_$SimulationQueueModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SimulationQueueModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queueId = null,
    Object? userId = null,
    Object? topologyId = null,
    Object? status = null,
    Object? priority = null,
    Object? requestedAt = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? workerId = freezed,
    Object? retryCount = null,
  }) {
    return _then(
      _$SimulationQueueModelImpl(
        queueId: null == queueId
            ? _value.queueId
            : queueId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        topologyId: null == topologyId
            ? _value.topologyId
            : topologyId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as QueueStatus,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        requestedAt: null == requestedAt
            ? _value.requestedAt
            : requestedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        workerId: freezed == workerId
            ? _value.workerId
            : workerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        retryCount: null == retryCount
            ? _value.retryCount
            : retryCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SimulationQueueModelImpl implements _SimulationQueueModel {
  const _$SimulationQueueModelImpl({
    required this.queueId,
    required this.userId,
    required this.topologyId,
    @JsonKey(unknownEnumValue: QueueStatus.queued)
    this.status = QueueStatus.queued,
    this.priority = 1,
    @TimestampConverter() required this.requestedAt,
    @NullableTimestampConverter() this.startedAt,
    @NullableTimestampConverter() this.completedAt,
    this.workerId,
    this.retryCount = 0,
  });

  factory _$SimulationQueueModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SimulationQueueModelImplFromJson(json);

  @override
  final String queueId;
  @override
  final String userId;
  @override
  final String topologyId;
  @override
  @JsonKey(unknownEnumValue: QueueStatus.queued)
  final QueueStatus status;
  @override
  @JsonKey()
  final int priority;
  @override
  @TimestampConverter()
  final DateTime requestedAt;
  @override
  @NullableTimestampConverter()
  final DateTime? startedAt;
  @override
  @NullableTimestampConverter()
  final DateTime? completedAt;
  @override
  final String? workerId;
  @override
  @JsonKey()
  final int retryCount;

  @override
  String toString() {
    return 'SimulationQueueModel(queueId: $queueId, userId: $userId, topologyId: $topologyId, status: $status, priority: $priority, requestedAt: $requestedAt, startedAt: $startedAt, completedAt: $completedAt, workerId: $workerId, retryCount: $retryCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimulationQueueModelImpl &&
            (identical(other.queueId, queueId) || other.queueId == queueId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.topologyId, topologyId) ||
                other.topologyId == topologyId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.workerId, workerId) ||
                other.workerId == workerId) &&
            (identical(other.retryCount, retryCount) ||
                other.retryCount == retryCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    queueId,
    userId,
    topologyId,
    status,
    priority,
    requestedAt,
    startedAt,
    completedAt,
    workerId,
    retryCount,
  );

  /// Create a copy of SimulationQueueModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimulationQueueModelImplCopyWith<_$SimulationQueueModelImpl>
  get copyWith =>
      __$$SimulationQueueModelImplCopyWithImpl<_$SimulationQueueModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SimulationQueueModelImplToJson(this);
  }
}

abstract class _SimulationQueueModel implements SimulationQueueModel {
  const factory _SimulationQueueModel({
    required final String queueId,
    required final String userId,
    required final String topologyId,
    @JsonKey(unknownEnumValue: QueueStatus.queued) final QueueStatus status,
    final int priority,
    @TimestampConverter() required final DateTime requestedAt,
    @NullableTimestampConverter() final DateTime? startedAt,
    @NullableTimestampConverter() final DateTime? completedAt,
    final String? workerId,
    final int retryCount,
  }) = _$SimulationQueueModelImpl;

  factory _SimulationQueueModel.fromJson(Map<String, dynamic> json) =
      _$SimulationQueueModelImpl.fromJson;

  @override
  String get queueId;
  @override
  String get userId;
  @override
  String get topologyId;
  @override
  @JsonKey(unknownEnumValue: QueueStatus.queued)
  QueueStatus get status;
  @override
  int get priority;
  @override
  @TimestampConverter()
  DateTime get requestedAt;
  @override
  @NullableTimestampConverter()
  DateTime? get startedAt;
  @override
  @NullableTimestampConverter()
  DateTime? get completedAt;
  @override
  String? get workerId;
  @override
  int get retryCount;

  /// Create a copy of SimulationQueueModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimulationQueueModelImplCopyWith<_$SimulationQueueModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SimulationResultModel _$SimulationResultModelFromJson(
  Map<String, dynamic> json,
) {
  return _SimulationResultModel.fromJson(json);
}

/// @nodoc
mixin _$SimulationResultModel {
  String get resultId => throw _privateConstructorUsedError;
  String get queueId => throw _privateConstructorUsedError;
  String get topologyId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get totalScore => throw _privateConstructorUsedError;
  int get maxScore => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get breakdown =>
      throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get completedAt => throw _privateConstructorUsedError;

  /// Serializes this SimulationResultModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SimulationResultModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimulationResultModelCopyWith<SimulationResultModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimulationResultModelCopyWith<$Res> {
  factory $SimulationResultModelCopyWith(
    SimulationResultModel value,
    $Res Function(SimulationResultModel) then,
  ) = _$SimulationResultModelCopyWithImpl<$Res, SimulationResultModel>;
  @useResult
  $Res call({
    String resultId,
    String queueId,
    String topologyId,
    String userId,
    int totalScore,
    int maxScore,
    double percentage,
    List<Map<String, dynamic>> breakdown,
    @TimestampConverter() DateTime completedAt,
  });
}

/// @nodoc
class _$SimulationResultModelCopyWithImpl<
  $Res,
  $Val extends SimulationResultModel
>
    implements $SimulationResultModelCopyWith<$Res> {
  _$SimulationResultModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SimulationResultModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultId = null,
    Object? queueId = null,
    Object? topologyId = null,
    Object? userId = null,
    Object? totalScore = null,
    Object? maxScore = null,
    Object? percentage = null,
    Object? breakdown = null,
    Object? completedAt = null,
  }) {
    return _then(
      _value.copyWith(
            resultId: null == resultId
                ? _value.resultId
                : resultId // ignore: cast_nullable_to_non_nullable
                      as String,
            queueId: null == queueId
                ? _value.queueId
                : queueId // ignore: cast_nullable_to_non_nullable
                      as String,
            topologyId: null == topologyId
                ? _value.topologyId
                : topologyId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalScore: null == totalScore
                ? _value.totalScore
                : totalScore // ignore: cast_nullable_to_non_nullable
                      as int,
            maxScore: null == maxScore
                ? _value.maxScore
                : maxScore // ignore: cast_nullable_to_non_nullable
                      as int,
            percentage: null == percentage
                ? _value.percentage
                : percentage // ignore: cast_nullable_to_non_nullable
                      as double,
            breakdown: null == breakdown
                ? _value.breakdown
                : breakdown // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            completedAt: null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SimulationResultModelImplCopyWith<$Res>
    implements $SimulationResultModelCopyWith<$Res> {
  factory _$$SimulationResultModelImplCopyWith(
    _$SimulationResultModelImpl value,
    $Res Function(_$SimulationResultModelImpl) then,
  ) = __$$SimulationResultModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String resultId,
    String queueId,
    String topologyId,
    String userId,
    int totalScore,
    int maxScore,
    double percentage,
    List<Map<String, dynamic>> breakdown,
    @TimestampConverter() DateTime completedAt,
  });
}

/// @nodoc
class __$$SimulationResultModelImplCopyWithImpl<$Res>
    extends
        _$SimulationResultModelCopyWithImpl<$Res, _$SimulationResultModelImpl>
    implements _$$SimulationResultModelImplCopyWith<$Res> {
  __$$SimulationResultModelImplCopyWithImpl(
    _$SimulationResultModelImpl _value,
    $Res Function(_$SimulationResultModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SimulationResultModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultId = null,
    Object? queueId = null,
    Object? topologyId = null,
    Object? userId = null,
    Object? totalScore = null,
    Object? maxScore = null,
    Object? percentage = null,
    Object? breakdown = null,
    Object? completedAt = null,
  }) {
    return _then(
      _$SimulationResultModelImpl(
        resultId: null == resultId
            ? _value.resultId
            : resultId // ignore: cast_nullable_to_non_nullable
                  as String,
        queueId: null == queueId
            ? _value.queueId
            : queueId // ignore: cast_nullable_to_non_nullable
                  as String,
        topologyId: null == topologyId
            ? _value.topologyId
            : topologyId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalScore: null == totalScore
            ? _value.totalScore
            : totalScore // ignore: cast_nullable_to_non_nullable
                  as int,
        maxScore: null == maxScore
            ? _value.maxScore
            : maxScore // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _value.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        breakdown: null == breakdown
            ? _value._breakdown
            : breakdown // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        completedAt: null == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SimulationResultModelImpl implements _SimulationResultModel {
  const _$SimulationResultModelImpl({
    required this.resultId,
    required this.queueId,
    required this.topologyId,
    required this.userId,
    this.totalScore = 0,
    this.maxScore = 100,
    this.percentage = 0.0,
    final List<Map<String, dynamic>> breakdown = const [],
    @TimestampConverter() required this.completedAt,
  }) : _breakdown = breakdown;

  factory _$SimulationResultModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SimulationResultModelImplFromJson(json);

  @override
  final String resultId;
  @override
  final String queueId;
  @override
  final String topologyId;
  @override
  final String userId;
  @override
  @JsonKey()
  final int totalScore;
  @override
  @JsonKey()
  final int maxScore;
  @override
  @JsonKey()
  final double percentage;
  final List<Map<String, dynamic>> _breakdown;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get breakdown {
    if (_breakdown is EqualUnmodifiableListView) return _breakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_breakdown);
  }

  @override
  @TimestampConverter()
  final DateTime completedAt;

  @override
  String toString() {
    return 'SimulationResultModel(resultId: $resultId, queueId: $queueId, topologyId: $topologyId, userId: $userId, totalScore: $totalScore, maxScore: $maxScore, percentage: $percentage, breakdown: $breakdown, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimulationResultModelImpl &&
            (identical(other.resultId, resultId) ||
                other.resultId == resultId) &&
            (identical(other.queueId, queueId) || other.queueId == queueId) &&
            (identical(other.topologyId, topologyId) ||
                other.topologyId == topologyId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore) &&
            (identical(other.maxScore, maxScore) ||
                other.maxScore == maxScore) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            const DeepCollectionEquality().equals(
              other._breakdown,
              _breakdown,
            ) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    resultId,
    queueId,
    topologyId,
    userId,
    totalScore,
    maxScore,
    percentage,
    const DeepCollectionEquality().hash(_breakdown),
    completedAt,
  );

  /// Create a copy of SimulationResultModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimulationResultModelImplCopyWith<_$SimulationResultModelImpl>
  get copyWith =>
      __$$SimulationResultModelImplCopyWithImpl<_$SimulationResultModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SimulationResultModelImplToJson(this);
  }
}

abstract class _SimulationResultModel implements SimulationResultModel {
  const factory _SimulationResultModel({
    required final String resultId,
    required final String queueId,
    required final String topologyId,
    required final String userId,
    final int totalScore,
    final int maxScore,
    final double percentage,
    final List<Map<String, dynamic>> breakdown,
    @TimestampConverter() required final DateTime completedAt,
  }) = _$SimulationResultModelImpl;

  factory _SimulationResultModel.fromJson(Map<String, dynamic> json) =
      _$SimulationResultModelImpl.fromJson;

  @override
  String get resultId;
  @override
  String get queueId;
  @override
  String get topologyId;
  @override
  String get userId;
  @override
  int get totalScore;
  @override
  int get maxScore;
  @override
  double get percentage;
  @override
  List<Map<String, dynamic>> get breakdown;
  @override
  @TimestampConverter()
  DateTime get completedAt;

  /// Create a copy of SimulationResultModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimulationResultModelImplCopyWith<_$SimulationResultModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
