import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/utils/validators.dart';

void main() {
  group('Validators Utility Unit Tests', () {
    test('isValidMatricNumber accepts valid NT matriculation numbers', () {
      expect(Validators.isValidMatricNumber('NT20240111512'), isTrue);
      expect(Validators.isValidMatricNumber('nt20240111512'), isTrue);
      expect(Validators.isValidMatricNumber('NT202612345'), isTrue);
    });

    test('isValidMatricNumber rejects invalid matriculation numbers', () {
      expect(Validators.isValidMatricNumber('CS20240111512'), isFalse); // Non-NT prefix
      expect(Validators.isValidMatricNumber('NT2024'), isFalse); // Too short
      expect(Validators.isValidMatricNumber('123456789'), isFalse);
      expect(Validators.isValidMatricNumber(''), isFalse);
    });

    test('isMatricNumber identifies student matriculation inputs', () {
      expect(Validators.isMatricNumber('NT20240111512'), isTrue);
      expect(Validators.isMatricNumber('NT9999'), isTrue);
      expect(Validators.isMatricNumber('alex@univ.edu'), isFalse);
    });

    test('isValidEmail validates institutional emails', () {
      expect(Validators.isValidEmail('alex.johnson@univ.edu'), isTrue);
      expect(Validators.isValidEmail('invalid-email'), isFalse);
    });

    test('isPasswordValid enforces length requirements', () {
      expect(Validators.isPasswordValid('123456'), isTrue);
      expect(Validators.isPasswordValid('12345'), isFalse);
    });
  });
}
