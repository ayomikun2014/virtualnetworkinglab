// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(
  Map<String, dynamic> json,
) => _$UserModelImpl(
  uid: json['uid'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  photoURL: json['photoURL'] as String?,
  studentIdNumber: json['studentIdNumber'] as String?,
  role:
      $enumDecodeNullable(
        _$UserRoleEnumMap,
        json['role'],
        unknownValue: UserRole.unknown,
      ) ??
      UserRole.student,
  departmentId: json['departmentId'] as String,
  taughtClassIds: (json['taughtClassIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  enrolledCourseIds: (json['enrolledCourseIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  freePracticeLevel: (json['freePracticeLevel'] as num?)?.toInt() ?? 1,
  points: (json['points'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  approvalStatus: json['approvalStatus'] as String? ?? 'approved',
  assignedCourses:
      (json['assignedCourses'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ??
      const [],
  lastLoginAt: const TimestampConverter().fromJson(
    json['lastLoginAt'] as Object,
  ),
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt'] as Object),
  stats: json['stats'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'studentIdNumber': instance.studentIdNumber,
      'role': _$UserRoleEnumMap[instance.role]!,
      'departmentId': instance.departmentId,
      'taughtClassIds': instance.taughtClassIds,
      'enrolledCourseIds': instance.enrolledCourseIds,
      'freePracticeLevel': instance.freePracticeLevel,
      'points': instance.points,
      'isActive': instance.isActive,
      'approvalStatus': instance.approvalStatus,
      'assignedCourses': instance.assignedCourses,
      'lastLoginAt': const TimestampConverter().toJson(instance.lastLoginAt),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'stats': instance.stats,
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.lecturer: 'lecturer',
  UserRole.admin: 'admin',
  UserRole.unknown: 'unknown',
};
