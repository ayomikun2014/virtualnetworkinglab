import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'simulation_model.freezed.dart';
part 'simulation_model.g.dart';

/// Asynchronous Simulation Queue Job Model
@freezed
class SimulationQueueModel with _$SimulationQueueModel {
  const factory SimulationQueueModel({
    required String queueId,
    required String userId,
    required String topologyId,
    @Default(QueueStatus.queued)
    @JsonKey(unknownEnumValue: QueueStatus.queued)
    QueueStatus status,
    @Default(1) int priority,
    @TimestampConverter() required DateTime requestedAt,
    @NullableTimestampConverter() DateTime? startedAt,
    @NullableTimestampConverter() DateTime? completedAt,
    String? workerId,
    @Default(0) int retryCount,
  }) = _SimulationQueueModel;

  factory SimulationQueueModel.fromJson(Map<String, dynamic> json) => _$SimulationQueueModelFromJson(json);
}

/// Simulation Run Execution Outcome Result Model
@freezed
class SimulationResultModel with _$SimulationResultModel {
  const factory SimulationResultModel({
    required String resultId,
    required String queueId,
    required String topologyId,
    required String userId,
    @Default(0) int totalScore,
    @Default(100) int maxScore,
    @Default(0.0) double percentage,
    @Default([]) List<Map<String, dynamic>> breakdown,
    @TimestampConverter() required DateTime completedAt,
  }) = _SimulationResultModel;

  factory SimulationResultModel.fromJson(Map<String, dynamic> json) => _$SimulationResultModelFromJson(json);
}
