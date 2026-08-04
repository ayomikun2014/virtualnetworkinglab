// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClassModelImpl _$$ClassModelImplFromJson(
  Map<String, dynamic> json,
) => _$ClassModelImpl(
  classId: json['classId'] as String,
  courseId: json['courseId'] as String,
  name: json['name'] as String,
  semester: json['semester'] as String,
  lecturerUid: json['lecturerUid'] as String,
  joinCode: json['joinCode'] as String,
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
  isArchived: json['isArchived'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$$ClassModelImplToJson(_$ClassModelImpl instance) =>
    <String, dynamic>{
      'classId': instance.classId,
      'courseId': instance.courseId,
      'name': instance.name,
      'semester': instance.semester,
      'lecturerUid': instance.lecturerUid,
      'joinCode': instance.joinCode,
      'memberCount': instance.memberCount,
      'isArchived': instance.isArchived,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

_$ClassMemberModelImpl _$$ClassMemberModelImplFromJson(
  Map<String, dynamic> json,
) => _$ClassMemberModelImpl(
  memberId: json['memberId'] as String,
  classId: json['classId'] as String,
  studentUid: json['studentUid'] as String,
  status:
      $enumDecodeNullable(
        _$MemberStatusEnumMap,
        json['status'],
        unknownValue: MemberStatus.active,
      ) ??
      MemberStatus.active,
  joinedAt: const TimestampConverter().fromJson(json['joinedAt'] as Object),
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
);

Map<String, dynamic> _$$ClassMemberModelImplToJson(
  _$ClassMemberModelImpl instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'classId': instance.classId,
  'studentUid': instance.studentUid,
  'status': _$MemberStatusEnumMap[instance.status]!,
  'joinedAt': const TimestampConverter().toJson(instance.joinedAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$MemberStatusEnumMap = {
  MemberStatus.active: 'active',
  MemberStatus.dropped: 'dropped',
  MemberStatus.pendingApproval: 'pending_approval',
};
