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

    /// Course this exercise belongs to. Students see it when this matches one
    /// of their `enrolledCourseIds`.
    required String categoryId,

    /// Human-readable course name, denormalised onto the exercise so the
    /// student's assessment list can show it without a second read per card.
    @Default('') String courseTitle,
    @JsonKey(unknownEnumValue: ExerciseType.unknown)
    required ExerciseType exerciseType,
    required DifficultyLevel difficulty,
    required String authorUid,
    required String initialTopologyId,
    @Default(100) int maxScore,
    @Default(true) bool isPublished,

    /// Closed to new submissions by the lecturer, independent of
    /// [isPublished] — a locked assessment still shows in the lecturer's
    /// Manage Exercises list and still shows students who already submitted
    /// their result, it just refuses anyone who hasn't attempted it yet.
    @Default(false) bool isLocked,
    int? practiceLevel,

    /// This exercise's position among every exercise published under the
    /// same [categoryId] — "Assessment 3" is the third exercise a lecturer
    /// has ever published for that course, in publish order. Computed once
    /// at publish time (see `LecturerManagementService.createExercise`), not
    /// derived at read time, so it stays stable even if earlier assessments
    /// are later unpublished. Null for a Free Practice level, which uses
    /// [practiceLevel] and its own "LEVEL N" numbering instead.
    int? assessmentNumber,

    /// Minutes a student has once they open this exercise, or null for no
    /// limit. When set, the canvas shows a countdown and auto-submits via
    /// Check Connection the moment it reaches zero — set by the lecturer at
    /// publish time, not something a student can change.
    int? timeLimitMinutes,
    Map<String, dynamic>? securityConfig,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}
