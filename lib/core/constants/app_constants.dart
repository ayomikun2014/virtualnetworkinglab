/// VirtuaNetLab Application Constants
///
/// Defines the root namespace and collection path getters across Cloud Firestore.
class AppConstants {
  AppConstants._();

  /// Root document path for VirtuaNetLab multi-project namespace isolation
  static const String rootPath = 'virtuanetlab/app';

  /// Collection path getters
  static String get usersCollection => '$rootPath/users';
  static String get classesCollection => '$rootPath/classes';
  static String get classMembersCollection => '$rootPath/class_members';
  static String get coursesCollection => '$rootPath/courses';
  static String get courseExercisesCollection => '$rootPath/course_exercises';
  static String get exerciseCategoriesCollection =>
      '$rootPath/exercise_categories';
  static String get exercisesCollection => '$rootPath/exercises';
  static String get exerciseAttemptsCollection => '$rootPath/exercise_attempts';
  static String get submissionsCollection => '$rootPath/submissions';
  static String get topologiesCollection => '$rootPath/topologies';
  static String get studentProgressCollection => '$rootPath/student_progress';

  /// Device catalogue — the palette reads from this collection.
  static String get deviceCatalogueCollection => '$rootPath/device_catalogue';

  /// Topics and their nested levels.
  static String get topicsCollection => '$rootPath/topics';
  static String levelsCollection(String topicId) =>
      '$topicsCollection/$topicId/levels';

  /// Per-user progression and saved attempts.
  static String userProgressCollection(String uid) =>
      '$usersCollection/$uid/progress';
  static String userAttemptsCollection(String uid) =>
      '$usersCollection/$uid/attempts';
  static String get systemConfigsCollection => '$rootPath/system_configs';
  static String get rolesCollection => '$rootPath/roles';
  static String get announcementsCollection => '$rootPath/announcements';
  static String get leaderboardsCollection => '$rootPath/leaderboards';
  static String get savedTemplatesCollection => '$rootPath/saved_templates';
  static String get labSessionsCollection => '$rootPath/lab_sessions';
  static String get networkDevicesCollection => '$rootPath/network_devices';
  static String get deviceTemplatesCollection => '$rootPath/device_templates';
  static String get deviceIconsCollection => '$rootPath/device_icons';
  static String get feedbackCollection => '$rootPath/feedback';
  static String get analyticsDailyCollection => '$rootPath/analytics_daily';

  /// Time-partitioned collection path generators
  static String activityLogsCollection(String yyyyMm) =>
      '$rootPath/activity_logs_$yyyyMm';
  static String performanceMetricsCollection(String yyyyMmDd) =>
      '$rootPath/performance_metrics_$yyyyMmDd';

  /// User notifications subcollection path generator
  static String userNotificationsCollection(String uid) =>
      '$usersCollection/$uid/notifications';

  /// Topology versions subcollection path generator
  static String topologyVersionsCollection(String topologyId) =>
      '$topologiesCollection/$topologyId/versions';

  /// Exercise private solution key subcollection path
  static String exerciseSolutionKeyPath(String exerciseId) =>
      '$exercisesCollection/$exerciseId/private/solution_key';

  /// Storage bucket root path
  static const String storageRootPath = 'virtuanetlab/app';
}
