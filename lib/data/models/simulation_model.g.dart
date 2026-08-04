// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SimulationQueueModelImpl _$$SimulationQueueModelImplFromJson(
  Map<String, dynamic> json,
) => _$SimulationQueueModelImpl(
  queueId: json['queueId'] as String,
  userId: json['userId'] as String,
  topologyId: json['topologyId'] as String,
  status:
      $enumDecodeNullable(
        _$QueueStatusEnumMap,
        json['status'],
        unknownValue: QueueStatus.queued,
      ) ??
      QueueStatus.queued,
  priority: (json['priority'] as num?)?.toInt() ?? 1,
  requestedAt: const TimestampConverter().fromJson(
    json['requestedAt'] as Object,
  ),
  startedAt: const NullableTimestampConverter().fromJson(json['startedAt']),
  completedAt: const NullableTimestampConverter().fromJson(json['completedAt']),
  workerId: json['workerId'] as String?,
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$SimulationQueueModelImplToJson(
  _$SimulationQueueModelImpl instance,
) => <String, dynamic>{
  'queueId': instance.queueId,
  'userId': instance.userId,
  'topologyId': instance.topologyId,
  'status': _$QueueStatusEnumMap[instance.status]!,
  'priority': instance.priority,
  'requestedAt': const TimestampConverter().toJson(instance.requestedAt),
  'startedAt': const NullableTimestampConverter().toJson(instance.startedAt),
  'completedAt': const NullableTimestampConverter().toJson(
    instance.completedAt,
  ),
  'workerId': instance.workerId,
  'retryCount': instance.retryCount,
};

const _$QueueStatusEnumMap = {
  QueueStatus.queued: 'queued',
  QueueStatus.processing: 'processing',
  QueueStatus.completed: 'completed',
  QueueStatus.failed: 'failed',
};

_$SimulationResultModelImpl _$$SimulationResultModelImplFromJson(
  Map<String, dynamic> json,
) => _$SimulationResultModelImpl(
  resultId: json['resultId'] as String,
  queueId: json['queueId'] as String,
  topologyId: json['topologyId'] as String,
  userId: json['userId'] as String,
  totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
  maxScore: (json['maxScore'] as num?)?.toInt() ?? 100,
  percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
  breakdown:
      (json['breakdown'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  completedAt: const TimestampConverter().fromJson(
    json['completedAt'] as Object,
  ),
);

Map<String, dynamic> _$$SimulationResultModelImplToJson(
  _$SimulationResultModelImpl instance,
) => <String, dynamic>{
  'resultId': instance.resultId,
  'queueId': instance.queueId,
  'topologyId': instance.topologyId,
  'userId': instance.userId,
  'totalScore': instance.totalScore,
  'maxScore': instance.maxScore,
  'percentage': instance.percentage,
  'breakdown': instance.breakdown,
  'completedAt': const TimestampConverter().toJson(instance.completedAt),
};
