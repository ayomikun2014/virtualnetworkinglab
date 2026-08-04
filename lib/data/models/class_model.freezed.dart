// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ClassModel _$ClassModelFromJson(Map<String, dynamic> json) {
  return _ClassModel.fromJson(json);
}

/// @nodoc
mixin _$ClassModel {
  String get classId => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get semester => throw _privateConstructorUsedError;
  String get lecturerUid => throw _privateConstructorUsedError;
  String get joinCode => throw _privateConstructorUsedError;
  int get memberCount => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ClassModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClassModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassModelCopyWith<ClassModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassModelCopyWith<$Res> {
  factory $ClassModelCopyWith(
    ClassModel value,
    $Res Function(ClassModel) then,
  ) = _$ClassModelCopyWithImpl<$Res, ClassModel>;
  @useResult
  $Res call({
    String classId,
    String courseId,
    String name,
    String semester,
    String lecturerUid,
    String joinCode,
    int memberCount,
    bool isArchived,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$ClassModelCopyWithImpl<$Res, $Val extends ClassModel>
    implements $ClassModelCopyWith<$Res> {
  _$ClassModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? courseId = null,
    Object? name = null,
    Object? semester = null,
    Object? lecturerUid = null,
    Object? joinCode = null,
    Object? memberCount = null,
    Object? isArchived = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            classId: null == classId
                ? _value.classId
                : classId // ignore: cast_nullable_to_non_nullable
                      as String,
            courseId: null == courseId
                ? _value.courseId
                : courseId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            semester: null == semester
                ? _value.semester
                : semester // ignore: cast_nullable_to_non_nullable
                      as String,
            lecturerUid: null == lecturerUid
                ? _value.lecturerUid
                : lecturerUid // ignore: cast_nullable_to_non_nullable
                      as String,
            joinCode: null == joinCode
                ? _value.joinCode
                : joinCode // ignore: cast_nullable_to_non_nullable
                      as String,
            memberCount: null == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isArchived: null == isArchived
                ? _value.isArchived
                : isArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$ClassModelImplCopyWith<$Res>
    implements $ClassModelCopyWith<$Res> {
  factory _$$ClassModelImplCopyWith(
    _$ClassModelImpl value,
    $Res Function(_$ClassModelImpl) then,
  ) = __$$ClassModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String classId,
    String courseId,
    String name,
    String semester,
    String lecturerUid,
    String joinCode,
    int memberCount,
    bool isArchived,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$ClassModelImplCopyWithImpl<$Res>
    extends _$ClassModelCopyWithImpl<$Res, _$ClassModelImpl>
    implements _$$ClassModelImplCopyWith<$Res> {
  __$$ClassModelImplCopyWithImpl(
    _$ClassModelImpl _value,
    $Res Function(_$ClassModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClassModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? classId = null,
    Object? courseId = null,
    Object? name = null,
    Object? semester = null,
    Object? lecturerUid = null,
    Object? joinCode = null,
    Object? memberCount = null,
    Object? isArchived = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ClassModelImpl(
        classId: null == classId
            ? _value.classId
            : classId // ignore: cast_nullable_to_non_nullable
                  as String,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        semester: null == semester
            ? _value.semester
            : semester // ignore: cast_nullable_to_non_nullable
                  as String,
        lecturerUid: null == lecturerUid
            ? _value.lecturerUid
            : lecturerUid // ignore: cast_nullable_to_non_nullable
                  as String,
        joinCode: null == joinCode
            ? _value.joinCode
            : joinCode // ignore: cast_nullable_to_non_nullable
                  as String,
        memberCount: null == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isArchived: null == isArchived
            ? _value.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$ClassModelImpl implements _ClassModel {
  const _$ClassModelImpl({
    required this.classId,
    required this.courseId,
    required this.name,
    required this.semester,
    required this.lecturerUid,
    required this.joinCode,
    this.memberCount = 0,
    this.isArchived = false,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
  });

  factory _$ClassModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClassModelImplFromJson(json);

  @override
  final String classId;
  @override
  final String courseId;
  @override
  final String name;
  @override
  final String semester;
  @override
  final String lecturerUid;
  @override
  final String joinCode;
  @override
  @JsonKey()
  final int memberCount;
  @override
  @JsonKey()
  final bool isArchived;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ClassModel(classId: $classId, courseId: $courseId, name: $name, semester: $semester, lecturerUid: $lecturerUid, joinCode: $joinCode, memberCount: $memberCount, isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassModelImpl &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.semester, semester) ||
                other.semester == semester) &&
            (identical(other.lecturerUid, lecturerUid) ||
                other.lecturerUid == lecturerUid) &&
            (identical(other.joinCode, joinCode) ||
                other.joinCode == joinCode) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    classId,
    courseId,
    name,
    semester,
    lecturerUid,
    joinCode,
    memberCount,
    isArchived,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ClassModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassModelImplCopyWith<_$ClassModelImpl> get copyWith =>
      __$$ClassModelImplCopyWithImpl<_$ClassModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClassModelImplToJson(this);
  }
}

abstract class _ClassModel implements ClassModel {
  const factory _ClassModel({
    required final String classId,
    required final String courseId,
    required final String name,
    required final String semester,
    required final String lecturerUid,
    required final String joinCode,
    final int memberCount,
    final bool isArchived,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
  }) = _$ClassModelImpl;

  factory _ClassModel.fromJson(Map<String, dynamic> json) =
      _$ClassModelImpl.fromJson;

  @override
  String get classId;
  @override
  String get courseId;
  @override
  String get name;
  @override
  String get semester;
  @override
  String get lecturerUid;
  @override
  String get joinCode;
  @override
  int get memberCount;
  @override
  bool get isArchived;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of ClassModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassModelImplCopyWith<_$ClassModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClassMemberModel _$ClassMemberModelFromJson(Map<String, dynamic> json) {
  return _ClassMemberModel.fromJson(json);
}

/// @nodoc
mixin _$ClassMemberModel {
  String get memberId => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get studentUid => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: MemberStatus.active)
  MemberStatus get status => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get joinedAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ClassMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClassMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClassMemberModelCopyWith<ClassMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassMemberModelCopyWith<$Res> {
  factory $ClassMemberModelCopyWith(
    ClassMemberModel value,
    $Res Function(ClassMemberModel) then,
  ) = _$ClassMemberModelCopyWithImpl<$Res, ClassMemberModel>;
  @useResult
  $Res call({
    String memberId,
    String classId,
    String studentUid,
    @JsonKey(unknownEnumValue: MemberStatus.active) MemberStatus status,
    @TimestampConverter() DateTime joinedAt,
    @TimestampConverter() DateTime createdAt,
  });
}

/// @nodoc
class _$ClassMemberModelCopyWithImpl<$Res, $Val extends ClassMemberModel>
    implements $ClassMemberModelCopyWith<$Res> {
  _$ClassMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClassMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? classId = null,
    Object? studentUid = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            memberId: null == memberId
                ? _value.memberId
                : memberId // ignore: cast_nullable_to_non_nullable
                      as String,
            classId: null == classId
                ? _value.classId
                : classId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentUid: null == studentUid
                ? _value.studentUid
                : studentUid // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as MemberStatus,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClassMemberModelImplCopyWith<$Res>
    implements $ClassMemberModelCopyWith<$Res> {
  factory _$$ClassMemberModelImplCopyWith(
    _$ClassMemberModelImpl value,
    $Res Function(_$ClassMemberModelImpl) then,
  ) = __$$ClassMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String memberId,
    String classId,
    String studentUid,
    @JsonKey(unknownEnumValue: MemberStatus.active) MemberStatus status,
    @TimestampConverter() DateTime joinedAt,
    @TimestampConverter() DateTime createdAt,
  });
}

/// @nodoc
class __$$ClassMemberModelImplCopyWithImpl<$Res>
    extends _$ClassMemberModelCopyWithImpl<$Res, _$ClassMemberModelImpl>
    implements _$$ClassMemberModelImplCopyWith<$Res> {
  __$$ClassMemberModelImplCopyWithImpl(
    _$ClassMemberModelImpl _value,
    $Res Function(_$ClassMemberModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClassMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? classId = null,
    Object? studentUid = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ClassMemberModelImpl(
        memberId: null == memberId
            ? _value.memberId
            : memberId // ignore: cast_nullable_to_non_nullable
                  as String,
        classId: null == classId
            ? _value.classId
            : classId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentUid: null == studentUid
            ? _value.studentUid
            : studentUid // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as MemberStatus,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClassMemberModelImpl implements _ClassMemberModel {
  const _$ClassMemberModelImpl({
    required this.memberId,
    required this.classId,
    required this.studentUid,
    @JsonKey(unknownEnumValue: MemberStatus.active)
    this.status = MemberStatus.active,
    @TimestampConverter() required this.joinedAt,
    @TimestampConverter() required this.createdAt,
  });

  factory _$ClassMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClassMemberModelImplFromJson(json);

  @override
  final String memberId;
  @override
  final String classId;
  @override
  final String studentUid;
  @override
  @JsonKey(unknownEnumValue: MemberStatus.active)
  final MemberStatus status;
  @override
  @TimestampConverter()
  final DateTime joinedAt;
  @override
  @TimestampConverter()
  final DateTime createdAt;

  @override
  String toString() {
    return 'ClassMemberModel(memberId: $memberId, classId: $classId, studentUid: $studentUid, status: $status, joinedAt: $joinedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassMemberModelImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.studentUid, studentUid) ||
                other.studentUid == studentUid) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    memberId,
    classId,
    studentUid,
    status,
    joinedAt,
    createdAt,
  );

  /// Create a copy of ClassMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassMemberModelImplCopyWith<_$ClassMemberModelImpl> get copyWith =>
      __$$ClassMemberModelImplCopyWithImpl<_$ClassMemberModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ClassMemberModelImplToJson(this);
  }
}

abstract class _ClassMemberModel implements ClassMemberModel {
  const factory _ClassMemberModel({
    required final String memberId,
    required final String classId,
    required final String studentUid,
    @JsonKey(unknownEnumValue: MemberStatus.active) final MemberStatus status,
    @TimestampConverter() required final DateTime joinedAt,
    @TimestampConverter() required final DateTime createdAt,
  }) = _$ClassMemberModelImpl;

  factory _ClassMemberModel.fromJson(Map<String, dynamic> json) =
      _$ClassMemberModelImpl.fromJson;

  @override
  String get memberId;
  @override
  String get classId;
  @override
  String get studentUid;
  @override
  @JsonKey(unknownEnumValue: MemberStatus.active)
  MemberStatus get status;
  @override
  @TimestampConverter()
  DateTime get joinedAt;
  @override
  @TimestampConverter()
  DateTime get createdAt;

  /// Create a copy of ClassMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClassMemberModelImplCopyWith<_$ClassMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
