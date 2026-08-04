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
  String get categoryId => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: ExerciseType.unknown)
  ExerciseType get exerciseType => throw _privateConstructorUsedError;
  DifficultyLevel get difficulty => throw _privateConstructorUsedError;
  String get authorUid => throw _privateConstructorUsedError;
  String get initialTopologyId => throw _privateConstructorUsedError;
  int get maxScore => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;
  int? get practiceLevel => throw _privateConstructorUsedError;
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
    @JsonKey(unknownEnumValue: ExerciseType.unknown) ExerciseType exerciseType,
    DifficultyLevel difficulty,
    String authorUid,
    String initialTopologyId,
    int maxScore,
    bool isPublished,
    int? practiceLevel,
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
    Object? exerciseType = null,
    Object? difficulty = null,
    Object? authorUid = null,
    Object? initialTopologyId = null,
    Object? maxScore = null,
    Object? isPublished = null,
    Object? practiceLevel = freezed,
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
            practiceLevel: freezed == practiceLevel
                ? _value.practiceLevel
                : practiceLevel // ignore: cast_nullable_to_non_nullable
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
    @JsonKey(unknownEnumValue: ExerciseType.unknown) ExerciseType exerciseType,
    DifficultyLevel difficulty,
    String authorUid,
    String initialTopologyId,
    int maxScore,
    bool isPublished,
    int? practiceLevel,
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
    Object? exerciseType = null,
    Object? difficulty = null,
    Object? authorUid = null,
    Object? initialTopologyId = null,
    Object? maxScore = null,
    Object? isPublished = null,
    Object? practiceLevel = freezed,
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
        practiceLevel: freezed == practiceLevel
            ? _value.practiceLevel
            : practiceLevel // ignore: cast_nullable_to_non_nullable
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
    @JsonKey(unknownEnumValue: ExerciseType.unknown) required this.exerciseType,
    required this.difficulty,
    required this.authorUid,
    required this.initialTopologyId,
    this.maxScore = 100,
    this.isPublished = true,
    this.practiceLevel,
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
  @override
  final String categoryId;
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
  @override
  final int? practiceLevel;
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
    return 'ExerciseModel(exerciseId: $exerciseId, title: $title, description: $description, categoryId: $categoryId, exerciseType: $exerciseType, difficulty: $difficulty, authorUid: $authorUid, initialTopologyId: $initialTopologyId, maxScore: $maxScore, isPublished: $isPublished, practiceLevel: $practiceLevel, securityConfig: $securityConfig, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.practiceLevel, practiceLevel) ||
                other.practiceLevel == practiceLevel) &&
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
    exerciseType,
    difficulty,
    authorUid,
    initialTopologyId,
    maxScore,
    isPublished,
    practiceLevel,
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
    @JsonKey(unknownEnumValue: ExerciseType.unknown)
    required final ExerciseType exerciseType,
    required final DifficultyLevel difficulty,
    required final String authorUid,
    required final String initialTopologyId,
    final int maxScore,
    final bool isPublished,
    final int? practiceLevel,
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
  @override
  String get categoryId;
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
  @override
  int? get practiceLevel;
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
