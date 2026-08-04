import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/constants/app_constants.dart';
import 'package:virtuanetlab/core/utils/timestamp_converter.dart';

void main() {
  group('Core Utilities Unit Tests', () {
    test('AppConstants returns correct collection namespace paths', () {
      expect(AppConstants.rootPath, equals('virtuanetlab/app'));
      expect(AppConstants.usersCollection, equals('virtuanetlab/app/users'));
      expect(AppConstants.topologiesCollection, equals('virtuanetlab/app/topologies'));
    });

    test('TimestampConverter parses ISO string and milliseconds correctly', () {
      const converter = TimestampConverter();
      final now = DateTime.now();

      final fromIso = converter.fromJson(now.toIso8601String());
      expect(fromIso.year, equals(now.year));

      final fromMillis = converter.fromJson(now.millisecondsSinceEpoch);
      expect(fromMillis.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });
}
