import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// Networking Exercise & Practice Level Model
@freezed
class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String exerciseId,
    required String title,
    required String description,
    required String categoryId,
    @JsonKey(unknownEnumValue: ExerciseType.unknown) required ExerciseType exerciseType,
    required DifficultyLevel difficulty,
    required String authorUid,
    required String initialTopologyId,
    @Default(100) int maxScore,
    @Default(true) bool isPublished,
    int? practiceLevel,
    Map<String, dynamic>? securityConfig,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);
}
