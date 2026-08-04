import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Custom JsonConverter to safely serialize and deserialize Cloud Firestore [Timestamp]
/// objects to Dart [DateTime] instances across Flutter Web and Native platforms.
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    } else if (json is Map) {
      // Handles raw map {_seconds: 12345, _nanoseconds: 67890}
      final seconds = json['_seconds'] as int? ?? json['seconds'] as int? ?? 0;
      final nanoseconds = json['_nanoseconds'] as int? ?? json['nanoseconds'] as int? ?? 0;
      return Timestamp(seconds, nanoseconds).toDate();
    }
    return DateTime.now();
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}

/// Nullable variant for optional DateTime fields
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    return const TimestampConverter().fromJson(json);
  }

  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
