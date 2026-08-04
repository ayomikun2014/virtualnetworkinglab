// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoURL => throw _privateConstructorUsedError;
  String? get studentIdNumber => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: UserRole.unknown)
  UserRole get role => throw _privateConstructorUsedError;
  String get departmentId => throw _privateConstructorUsedError;
  List<String>? get taughtClassIds => throw _privateConstructorUsedError;
  List<String>? get enrolledCourseIds => throw _privateConstructorUsedError;
  int get freePracticeLevel => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get lastLoginAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  Map<String, dynamic> get stats => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({
    String uid,
    String email,
    String displayName,
    String? photoURL,
    String? studentIdNumber,
    @JsonKey(unknownEnumValue: UserRole.unknown) UserRole role,
    String departmentId,
    List<String>? taughtClassIds,
    List<String>? enrolledCourseIds,
    int freePracticeLevel,
    bool isActive,
    @TimestampConverter() DateTime lastLoginAt,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
    Map<String, dynamic> stats,
  });
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? studentIdNumber = freezed,
    Object? role = null,
    Object? departmentId = null,
    Object? taughtClassIds = freezed,
    Object? enrolledCourseIds = freezed,
    Object? freePracticeLevel = null,
    Object? isActive = null,
    Object? lastLoginAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? stats = null,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            photoURL: freezed == photoURL
                ? _value.photoURL
                : photoURL // ignore: cast_nullable_to_non_nullable
                      as String?,
            studentIdNumber: freezed == studentIdNumber
                ? _value.studentIdNumber
                : studentIdNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as UserRole,
            departmentId: null == departmentId
                ? _value.departmentId
                : departmentId // ignore: cast_nullable_to_non_nullable
                      as String,
            taughtClassIds: freezed == taughtClassIds
                ? _value.taughtClassIds
                : taughtClassIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            enrolledCourseIds: freezed == enrolledCourseIds
                ? _value.enrolledCourseIds
                : enrolledCourseIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            freePracticeLevel: null == freePracticeLevel
                ? _value.freePracticeLevel
                : freePracticeLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastLoginAt: null == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            stats: null == stats
                ? _value.stats
                : stats // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
    _$UserModelImpl value,
    $Res Function(_$UserModelImpl) then,
  ) = __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String email,
    String displayName,
    String? photoURL,
    String? studentIdNumber,
    @JsonKey(unknownEnumValue: UserRole.unknown) UserRole role,
    String departmentId,
    List<String>? taughtClassIds,
    List<String>? enrolledCourseIds,
    int freePracticeLevel,
    bool isActive,
    @TimestampConverter() DateTime lastLoginAt,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
    Map<String, dynamic> stats,
  });
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
    _$UserModelImpl _value,
    $Res Function(_$UserModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? studentIdNumber = freezed,
    Object? role = null,
    Object? departmentId = null,
    Object? taughtClassIds = freezed,
    Object? enrolledCourseIds = freezed,
    Object? freePracticeLevel = null,
    Object? isActive = null,
    Object? lastLoginAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? stats = null,
  }) {
    return _then(
      _$UserModelImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        photoURL: freezed == photoURL
            ? _value.photoURL
            : photoURL // ignore: cast_nullable_to_non_nullable
                  as String?,
        studentIdNumber: freezed == studentIdNumber
            ? _value.studentIdNumber
            : studentIdNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as UserRole,
        departmentId: null == departmentId
            ? _value.departmentId
            : departmentId // ignore: cast_nullable_to_non_nullable
                  as String,
        taughtClassIds: freezed == taughtClassIds
            ? _value._taughtClassIds
            : taughtClassIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        enrolledCourseIds: freezed == enrolledCourseIds
            ? _value._enrolledCourseIds
            : enrolledCourseIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        freePracticeLevel: null == freePracticeLevel
            ? _value.freePracticeLevel
            : freePracticeLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastLoginAt: null == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        stats: null == stats
            ? _value._stats
            : stats // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.studentIdNumber,
    @JsonKey(unknownEnumValue: UserRole.unknown) this.role = UserRole.student,
    required this.departmentId,
    final List<String>? taughtClassIds,
    final List<String>? enrolledCourseIds,
    this.freePracticeLevel = 1,
    this.isActive = true,
    @TimestampConverter() required this.lastLoginAt,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
    final Map<String, dynamic> stats = const {},
  }) : _taughtClassIds = taughtClassIds,
       _enrolledCourseIds = enrolledCourseIds,
       _stats = stats;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String uid;
  @override
  final String email;
  @override
  final String displayName;
  @override
  final String? photoURL;
  @override
  final String? studentIdNumber;
  @override
  @JsonKey(unknownEnumValue: UserRole.unknown)
  final UserRole role;
  @override
  final String departmentId;
  final List<String>? _taughtClassIds;
  @override
  List<String>? get taughtClassIds {
    final value = _taughtClassIds;
    if (value == null) return null;
    if (_taughtClassIds is EqualUnmodifiableListView) return _taughtClassIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _enrolledCourseIds;
  @override
  List<String>? get enrolledCourseIds {
    final value = _enrolledCourseIds;
    if (value == null) return null;
    if (_enrolledCourseIds is EqualUnmodifiableListView)
      return _enrolledCourseIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final int freePracticeLevel;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @TimestampConverter()
  final DateTime lastLoginAt;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;
  final Map<String, dynamic> _stats;
  @override
  @JsonKey()
  Map<String, dynamic> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, photoURL: $photoURL, studentIdNumber: $studentIdNumber, role: $role, departmentId: $departmentId, taughtClassIds: $taughtClassIds, enrolledCourseIds: $enrolledCourseIds, freePracticeLevel: $freePracticeLevel, isActive: $isActive, lastLoginAt: $lastLoginAt, createdAt: $createdAt, updatedAt: $updatedAt, stats: $stats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.studentIdNumber, studentIdNumber) ||
                other.studentIdNumber == studentIdNumber) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.departmentId, departmentId) ||
                other.departmentId == departmentId) &&
            const DeepCollectionEquality().equals(
              other._taughtClassIds,
              _taughtClassIds,
            ) &&
            const DeepCollectionEquality().equals(
              other._enrolledCourseIds,
              _enrolledCourseIds,
            ) &&
            (identical(other.freePracticeLevel, freePracticeLevel) ||
                other.freePracticeLevel == freePracticeLevel) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._stats, _stats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    email,
    displayName,
    photoURL,
    studentIdNumber,
    role,
    departmentId,
    const DeepCollectionEquality().hash(_taughtClassIds),
    const DeepCollectionEquality().hash(_enrolledCourseIds),
    freePracticeLevel,
    isActive,
    lastLoginAt,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_stats),
  );

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(this);
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel({
    required final String uid,
    required final String email,
    required final String displayName,
    final String? photoURL,
    final String? studentIdNumber,
    @JsonKey(unknownEnumValue: UserRole.unknown) final UserRole role,
    required final String departmentId,
    final List<String>? taughtClassIds,
    final List<String>? enrolledCourseIds,
    final int freePracticeLevel,
    final bool isActive,
    @TimestampConverter() required final DateTime lastLoginAt,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
    final Map<String, dynamic> stats,
  }) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get uid;
  @override
  String get email;
  @override
  String get displayName;
  @override
  String? get photoURL;
  @override
  String? get studentIdNumber;
  @override
  @JsonKey(unknownEnumValue: UserRole.unknown)
  UserRole get role;
  @override
  String get departmentId;
  @override
  List<String>? get taughtClassIds;
  @override
  List<String>? get enrolledCourseIds;
  @override
  int get freePracticeLevel;
  @override
  bool get isActive;
  @override
  @TimestampConverter()
  DateTime get lastLoginAt;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;
  @override
  Map<String, dynamic> get stats;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
