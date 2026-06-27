import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/auth/domain/account_validation.dart';

void main() {
  group('validateEmail', () {
    test('returns null for a valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('returns error for empty string', () {
      expect(validateEmail(''), isNotNull);
    });

    test('returns error when @ is missing', () {
      expect(validateEmail('userexample.com'), isNotNull);
    });

    test('returns error when tld is missing', () {
      expect(validateEmail('user@example'), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(validateEmail('   '), isNotNull);
    });
  });

  group('validatePassword', () {
    test('returns error for a password shorter than 8 characters', () {
      expect(validatePassword('short'), isNotNull);
    });

    test('returns error for exactly 7 characters', () {
      expect(validatePassword('1234567'), isNotNull);
    });

    test('returns null for exactly 8 characters', () {
      expect(validatePassword('12345678'), isNull);
    });

    test('returns null for a long password', () {
      expect(validatePassword('a-perfectly-good-passphrase'), isNull);
    });
  });
}
