import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'class_model.freezed.dart';
part 'class_model.g.dart';

/// Class Cohort Model
@freezed
class ClassModel with _$ClassModel {
  const factory ClassModel({
    required String classId,
    required String courseId,
    required String name,
    required String semester,
    required String lecturerUid,
    required String joinCode,
    @Default(0) int memberCount,
    @Default(false) bool isArchived,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _ClassModel;

  factory ClassModel.fromJson(Map<String, dynamic> json) => _$ClassModelFromJson(json);
}

/// Class Roster Member Junction Model
@freezed
class ClassMemberModel with _$ClassMemberModel {
  const factory ClassMemberModel({
    required String memberId,
    required String classId,
    required String studentUid,
    @Default(MemberStatus.active)
    @JsonKey(unknownEnumValue: MemberStatus.active)
    MemberStatus status,
    @TimestampConverter() required DateTime joinedAt,
    @TimestampConverter() required DateTime createdAt,
  }) = _ClassMemberModel;

  factory ClassMemberModel.fromJson(Map<String, dynamic> json) => _$ClassMemberModelFromJson(json);
}
