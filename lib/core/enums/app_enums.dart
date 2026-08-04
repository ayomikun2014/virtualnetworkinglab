import 'package:json_annotation/json_annotation.dart';

/// User Role Classification
enum UserRole {
  @JsonValue('student')
  student,

  @JsonValue('lecturer')
  lecturer,

  @JsonValue('admin')
  admin,

  @JsonValue('unknown')
  unknown;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.lecturer:
        return 'Lecturer';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.unknown:
        return 'Unknown';
    }
  }
}

/// Networking Exercise Domain Types
enum ExerciseType {
  @JsonValue('routing')
  routing,

  @JsonValue('switching')
  switching,

  @JsonValue('subnetting')
  subnetting,

  @JsonValue('security')
  security,

  @JsonValue('wireless')
  wireless,

  @JsonValue('troubleshooting')
  troubleshooting,

  @JsonValue('unknown')
  unknown;

  String get displayName {
    switch (this) {
      case ExerciseType.routing:
        return 'Routing Protocols';
      case ExerciseType.switching:
        return 'Switching & VLANs';
      case ExerciseType.subnetting:
        return 'Subnetting & Addressing';
      case ExerciseType.security:
        return 'Network Security & ACLs';
      case ExerciseType.wireless:
        return 'Wireless Networking';
      case ExerciseType.troubleshooting:
        return 'Troubleshooting & Diagnostics';
      case ExerciseType.unknown:
        return 'General Networking';
    }
  }
}

/// Exercise Difficulty Metrics
enum DifficultyLevel {
  @JsonValue('beginner')
  beginner,

  @JsonValue('intermediate')
  intermediate,

  @JsonValue('advanced')
  advanced;

  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }
}

/// Asynchronous Simulation Queue Execution Status
enum QueueStatus {
  @JsonValue('queued')
  queued,

  @JsonValue('processing')
  processing,

  @JsonValue('completed')
  completed,

  @JsonValue('failed')
  failed;

  bool get isFinished => this == QueueStatus.completed || this == QueueStatus.failed;
}

/// Canvas Device Hardware Classification
enum DeviceType {
  @JsonValue('router')
  router,

  @JsonValue('switch')
  switchDevice,

  @JsonValue('firewall')
  firewall,

  @JsonValue('pc')
  pc,

  @JsonValue('server')
  server,

  @JsonValue('cloud')
  cloud;

  String get jsonValue {
    switch (this) {
      case DeviceType.router:
        return 'router';
      case DeviceType.switchDevice:
        return 'switch';
      case DeviceType.firewall:
        return 'firewall';
      case DeviceType.pc:
        return 'pc';
      case DeviceType.server:
        return 'server';
      case DeviceType.cloud:
        return 'cloud';
    }
  }
}

/// Class Roster Member Enrollment Status
enum MemberStatus {
  @JsonValue('active')
  active,

  @JsonValue('dropped')
  dropped,

  @JsonValue('pending_approval')
  pendingApproval;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.dropped:
        return 'Dropped';
      case MemberStatus.pendingApproval:
        return 'Pending Approval';
    }
  }
}
