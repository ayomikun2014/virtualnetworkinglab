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

    /// Running score. Passing a level adds points, a failed Check Connection
    /// spends some, and levels past the first need a couple in hand before
    /// they can be opened — so a student has to actually build something
    /// that works to keep moving. Never negative: see
    /// [IGradingRepository.applyPointsDelta].
    @Default(0) int points,
    @Default(true) bool isActive,

    /// Only meaningful for `role == lecturer`. A self-registered lecturer
    /// starts 'pending' and cannot reach the lecturer dashboard — the
    /// router sends them to a waiting screen instead — until an admin
    /// approves them and assigns courses, which flips this to 'approved'.
    /// Every other account (students, admins, and lecturers provisioned
    /// before this existed) defaults to 'approved' so nothing else is
    /// gated by a field it never asked for.
    @Default('approved') String approvalStatus,

    /// The courses a lecturer teaches, as {code, title} pairs — set by an
    /// admin at approval time (or edited later), not chosen by the
    /// lecturer. Empty for every non-lecturer.
    @Default([]) List<Map<String, String>> assignedCourses,
    @TimestampConverter() required DateTime lastLoginAt,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default({}) Map<String, dynamic> stats,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
