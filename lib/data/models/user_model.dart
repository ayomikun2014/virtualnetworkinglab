import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/app_enums.dart';
import '../../core/utils/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User Profile Model for VirtuaNetLab
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    String? studentIdNumber,
    @Default(UserRole.student)
    @JsonKey(unknownEnumValue: UserRole.unknown)
    UserRole role,
    required String departmentId,
    List<String>? taughtClassIds,
    List<String>? enrolledCourseIds,
    @Default(1) int freePracticeLevel,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime lastLoginAt,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default({}) Map<String, dynamic> stats,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
