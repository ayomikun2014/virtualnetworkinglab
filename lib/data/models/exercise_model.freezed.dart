// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) {
  return _ExerciseModel.fromJson(json);
}

/// @nodoc
mixin _$ExerciseModel {
  String get exerciseId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Course this exercise belongs to. Students see it when this matches one
  /// of their `enrolledCourseIds`.
  String get categoryId => throw _privateConstructorUsedError;

  /// Human-readable course name, denormalised onto the exercise so the
  /// student's assessment list can show it without a second read per card.
  String get courseTitle => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: ExerciseType.unknown)
  ExerciseType get exerciseType => throw _privateConstructorUsedError;
  DifficultyLevel get difficulty => throw _privateConstructorUsedError;
  String get authorUid => throw _privateConstructorUsedError;
  String get initialTopologyId => throw _privateConstructorUsedError;
  int get maxScore => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;

  /// Closed to new submissions by the lecturer, independent of
  /// [isPublished] — a locked assessment still shows in the lecturer's
  /// Manage Exercises list and still shows students who already submitted
  /// their result, it just refuses anyone who hasn't attempted it yet.
  bool get isLocked => throw _privateConstructorUsedError;
  int? get practiceLevel => throw _privateConstructorUsedError;

  /// This exercise's position among every exercise published under the
  /// same [categoryId] — "Assessment 3" is the third exercise a lecturer
  /// has ever published for that course, in publish order. Computed once
  /// at publish time (see `LecturerManagementService.createExercise`), not
  /// derived at read time, so it stays stable even if earlier assessments
  /// are later unpublished. Null for a Free Practice level, which uses
  /// [practiceLevel] and its own "LEVEL N" numbering instead.
  int? get assessmentNumber => throw _privateConstructorUsedError;

  /// Minutes a student has once they open this exercise, or null for no
  /// limit. When set, the canvas shows a countdown and auto-submits via
  /// Check Connection the moment it reaches zero — set by the lecturer at
  /// publish time, not something a student can change.
  int? get timeLimitMinutes => throw _privateConstructorUsedError;
  Map<String, dynamic>? get securityConfig =>
      throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseModelCopyWith<ExerciseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseModelCopyWith<$Res> {
  factory $ExerciseModelCopyWith(
    ExerciseModel value,
    $Res Function(ExerciseModel) then,
  ) = _$ExerciseModelCopyWithImpl<$Res, ExerciseModel>;
  @useResult
  $Res call({
    String exerciseId,
    String title,
    String description,
    String categoryId,
    String courseTitle,
    @JsonKey(unknownEnumValue: ExerciseType.unknown) ExerciseType exerciseType,
    DifficultyLevel difficulty,
    String authorUid,
    String initialTopologyId,
    int maxScore,
    bool isPublished,
    bool isLocked,
    int? practiceLevel,
    int? assessmentNumber,
    int? timeLimitMinutes,
    Map<String, dynamic>? securityConfig,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res, $Val extends ExerciseModel>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? courseTitle = null,
    Object? exerciseType = null,
    Object? difficulty = null,
    Object? authorUid = null,
    Object? initialTopologyId = null,
    Object? maxScore = null,
    Object? isPublished = null,
    Object? isLocked = null,
    Object? practiceLevel = freezed,
    Object? assessmentNumber = freezed,
    Object? timeLimitMinutes = freezed,
    Object? securityConfig = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            exerciseId: null == exerciseId
                ? _value.exerciseId
                : exerciseId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            courseTitle: null == courseTitle
                ? _value.courseTitle
                : courseTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            exerciseType: null == exerciseType
                ? _value.exerciseType
                : exerciseType // ignore: cast_nullable_to_non_nullable
                      as ExerciseType,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as DifficultyLevel,
            authorUid: null == authorUid
                ? _value.authorUid
                : authorUid // ignore: cast_nullable_to_non_nullable
                      as String,
            initialTopologyId: null == initialTopologyId
                ? _value.initialTopologyId
                : initialTopologyId // ignore: cast_nullable_to_non_nullable
                      as String,
            maxScore: null == maxScore
                ? _value.maxScore
                : maxScore // ignore: cast_nullable_to_non_nullable
                      as int,
            isPublished: null == isPublished
                ? _value.isPublished
                : isPublished // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLocked: null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            practiceLevel: freezed == practiceLevel
                ? _value.practiceLevel
                : practiceLevel // ignore: cast_nullable_to_non_nullable
                      as int?,
            assessmentNumber: freezed == assessmentNumber
                ? _value.assessmentNumber
                : assessmentNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            timeLimitMinutes: freezed == timeLimitMinutes
                ? _value.timeLimitMinutes
                : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            securityConfig: freezed == securityConfig
                ? _value.securityConfig
                : securityConfig // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
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
abstract class _$$ExerciseModelImplCopyWith<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  factory _$$ExerciseModelImplCopyWith(
    _$ExerciseModelImpl value,
    $Res Function(_$ExerciseModelImpl) then,
  ) = __$$ExerciseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String exerciseId,
    String title,
    String description,
    String categoryId,
    String courseTitle,
    @JsonKey(unknownEnumValue: ExerciseType.unknown) ExerciseType exerciseType,
    DifficultyLevel difficulty,
    String authorUid,
    String initialTopologyId,
    int maxScore,
    bool isPublished,
    bool isLocked,
    int? practiceLevel,
    int? assessmentNumber,
    int? timeLimitMinutes,
    Map<String, dynamic>? securityConfig,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$ExerciseModelImplCopyWithImpl<$Res>
    extends _$ExerciseModelCopyWithImpl<$Res, _$ExerciseModelImpl>
    implements _$$ExerciseModelImplCopyWith<$Res> {
  __$$ExerciseModelImplCopyWithImpl(
    _$ExerciseModelImpl _value,
    $Res Function(_$ExerciseModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? courseTitle = null,
    Object? exerciseType = null,
    Object? difficulty = null,
    Object? authorUid = null,
    Object? initialTopologyId = null,
    Object? maxScore = null,
    Object? isPublished = null,
    Object? isLocked = null,
    Object? practiceLevel = freezed,
    Object? assessmentNumber = freezed,
    Object? timeLimitMinutes = freezed,
    Object? securityConfig = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ExerciseModelImpl(
        exerciseId: null == exerciseId
            ? _value.exerciseId
            : exerciseId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        courseTitle: null == courseTitle
            ? _value.courseTitle
            : courseTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        exerciseType: null == exerciseType
            ? _value.exerciseType
            : exerciseType // ignore: cast_nullable_to_non_nullable
                  as ExerciseType,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as DifficultyLevel,
        authorUid: null == authorUid
            ? _value.authorUid
            : authorUid // ignore: cast_nullable_to_non_nullable
                  as String,
        initialTopologyId: null == initialTopologyId
            ? _value.initialTopologyId
            : initialTopologyId // ignore: cast_nullable_to_non_nullable
                  as String,
        maxScore: null == maxScore
            ? _value.maxScore
            : maxScore // ignore: cast_nullable_to_non_nullable
                  as int,
        isPublished: null == isPublished
            ? _value.isPublished
            : isPublished // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLocked: null == isLocked
            ? _value.isLocked
            : isLocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        practiceLevel: freezed == practiceLevel
            ? _value.practiceLevel
            : practiceLevel // ignore: cast_nullable_to_non_nullable
                  as int?,
        assessmentNumber: freezed == assessmentNumber
            ? _value.assessmentNumber
            : assessmentNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        timeLimitMinutes: freezed == timeLimitMinutes
            ? _value.timeLimitMinutes
            : timeLimitMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        securityConfig: freezed == securityConfig
            ? _value._securityConfig
            : securityConfig // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
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
class _$ExerciseModelImpl implements _ExerciseModel {
  const _$ExerciseModelImpl({
    required this.exerciseId,
    required this.title,
    required this.description,
    required this.categoryId,
    this.courseTitle = '',
    @JsonKey(unknownEnumValue: ExerciseType.unknown) required this.exerciseType,
    required this.difficulty,
    required this.authorUid,
    required this.initialTopologyId,
    this.maxScore = 100,
    this.isPublished = true,
    this.isLocked = false,
    this.practiceLevel,
    this.assessmentNumber,
    this.timeLimitMinutes,
    final Map<String, dynamic>? securityConfig,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
  }) : _securityConfig = securityConfig;

  factory _$ExerciseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseModelImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final String title;
  @override
  final String description;

  /// Course this exercise belongs to. Students see it when this matches one
  /// of their `enrolledCourseIds`.
  @override
  final String categoryId;

  /// Human-readable course name, denormalised onto the exercise so the
  /// student's assessment list can show it without a second read per card.
  @override
  @JsonKey()
  final String courseTitle;
  @override
  @JsonKey(unknownEnumValue: ExerciseType.unknown)
  final ExerciseType exerciseType;
  @override
  final DifficultyLevel difficulty;
  @override
  final String authorUid;
  @override
  final String initialTopologyId;
  @override
  @JsonKey()
  final int maxScore;
  @override
  @JsonKey()
  final bool isPublished;

  /// Closed to new submissions by the lecturer, independent of
  /// [isPublished] — a locked assessment still shows in the lecturer's
  /// Manage Exercises list and still shows students who already submitted
  /// their result, it just refuses anyone who hasn't attempted it yet.
  @override
  @JsonKey()
  final bool isLocked;
  @override
  final int? practiceLevel;

  /// This exercise's position among every exercise published under the
  /// same [categoryId] — "Assessment 3" is the third exercise a lecturer
  /// has ever published for that course, in publish order. Computed once
  /// at publish time (see `LecturerManagementService.createExercise`), not
  /// derived at read time, so it stays stable even if earlier assessments
  /// are later unpublished. Null for a Free Practice level, which uses
  /// [practiceLevel] and its own "LEVEL N" numbering instead.
  @override
  final int? assessmentNumber;

  /// Minutes a student has once they open this exercise, or null for no
  /// limit. When set, the canvas shows a countdown and auto-submits via
  /// Check Connection the moment it reaches zero — set by the lecturer at
  /// publish time, not something a student can change.
  @override
  final int? timeLimitMinutes;
  final Map<String, dynamic>? _securityConfig;
  @override
  Map<String, dynamic>? get securityConfig {
    final value = _securityConfig;
    if (value == null) return null;
    if (_securityConfig is EqualUnmodifiableMapView) return _securityConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ExerciseModel(exerciseId: $exerciseId, title: $title, description: $description, categoryId: $categoryId, courseTitle: $courseTitle, exerciseType: $exerciseType, difficulty: $difficulty, authorUid: $authorUid, initialTopologyId: $initialTopologyId, maxScore: $maxScore, isPublished: $isPublished, isLocked: $isLocked, practiceLevel: $practiceLevel, assessmentNumber: $assessmentNumber, timeLimitMinutes: $timeLimitMinutes, securityConfig: $securityConfig, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseModelImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.courseTitle, courseTitle) ||
                other.courseTitle == courseTitle) &&
            (identical(other.exerciseType, exerciseType) ||
                other.exerciseType == exerciseType) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.authorUid, authorUid) ||
                other.authorUid == authorUid) &&
            (identical(other.initialTopologyId, initialTopologyId) ||
                other.initialTopologyId == initialTopologyId) &&
            (identical(other.maxScore, maxScore) ||
                other.maxScore == maxScore) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.practiceLevel, practiceLevel) ||
                other.practiceLevel == practiceLevel) &&
            (identical(other.assessmentNumber, assessmentNumber) ||
                other.assessmentNumber == assessmentNumber) &&
            (identical(other.timeLimitMinutes, timeLimitMinutes) ||
                other.timeLimitMinutes == timeLimitMinutes) &&
            const DeepCollectionEquality().equals(
              other._securityConfig,
              _securityConfig,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    exerciseId,
    title,
    description,
    categoryId,
    courseTitle,
    exerciseType,
    difficulty,
    authorUid,
    initialTopologyId,
    maxScore,
    isPublished,
    isLocked,
    practiceLevel,
    assessmentNumber,
    timeLimitMinutes,
    const DeepCollectionEquality().hash(_securityConfig),
    createdAt,
    updatedAt,
  );

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      __$$ExerciseModelImplCopyWithImpl<_$ExerciseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseModelImplToJson(this);
  }
}

abstract class _ExerciseModel implements ExerciseModel {
  const factory _ExerciseModel({
    required final String exerciseId,
    required final String title,
    required final String description,
    required final String categoryId,
    final String courseTitle,
    @JsonKey(unknownEnumValue: ExerciseType.unknown)
    required final ExerciseType exerciseType,
    required final DifficultyLevel difficulty,
    required final String authorUid,
    required final String initialTopologyId,
    final int maxScore,
    final bool isPublished,
    final bool isLocked,
    final int? practiceLevel,
    final int? assessmentNumber,
    final int? timeLimitMinutes,
    final Map<String, dynamic>? securityConfig,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
  }) = _$ExerciseModelImpl;

  factory _ExerciseModel.fromJson(Map<String, dynamic> json) =
      _$ExerciseModelImpl.fromJson;

  @override
  String get exerciseId;
  @override
  String get title;
  @override
  String get description;

  /// Course this exercise belongs to. Students see it when this matches one
  /// of their `enrolledCourseIds`.
  @override
  String get categoryId;

  /// Human-readable course name, denormalised onto the exercise so the
  /// student's assessment list can show it without a second read per card.
  @override
  String get courseTitle;
  @override
  @JsonKey(unknownEnumValue: ExerciseType.unknown)
  ExerciseType get exerciseType;
  @override
  DifficultyLevel get difficulty;
  @override
  String get authorUid;
  @override
  String get initialTopologyId;
  @override
  int get maxScore;
  @override
  bool get isPublished;

  /// Closed to new submissions by the lecturer, independent of
  /// [isPublished] — a locked assessment still shows in the lecturer's
  /// Manage Exercises list and still shows students who already submitted
  /// their result, it just refuses anyone who hasn't attempted it yet.
  @override
  bool get isLocked;
  @override
  int? get practiceLevel;

  /// This exercise's position among every exercise published under the
  /// same [categoryId] — "Assessment 3" is the third exercise a lecturer
  /// has ever published for that course, in publish order. Computed once
  /// at publish time (see `LecturerManagementService.createExercise`), not
  /// derived at read time, so it stays stable even if earlier assessments
  /// are later unpublished. Null for a Free Practice level, which uses
  /// [practiceLevel] and its own "LEVEL N" numbering instead.
  @override
  int? get assessmentNumber;

  /// Minutes a student has once they open this exercise, or null for no
  /// limit. When set, the canvas shows a countdown and auto-submits via
  /// Check Connection the moment it reaches zero — set by the lecturer at
  /// publish time, not something a student can change.
  @override
  int? get timeLimitMinutes;
  @override
  Map<String, dynamic>? get securityConfig;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of ExerciseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseModelImplCopyWith<_$ExerciseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
