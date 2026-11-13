import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/security/app_security.dart';

void main() {
  group('PIN-only security validation', () {
    test('4 digits are rejected', () {
      expect(validateSpendWisePin('1234'), contains('at least 6 digits'));
    });
    test('6 digits are allowed', () {
      expect(validateSpendWisePin('123456'), isNull);
    });
    test('12 digits are allowed', () {
      expect(validateSpendWisePin('123456789012'), isNull);
    });
    test('13 digits are rejected', () {
      expect(validateSpendWisePin('1234567890123'), contains('12 digits'));
    });
    test('non-numeric PINs are rejected', () {
      expect(validateSpendWisePin('abc123'), contains('numbers only'));
    });
    test('empty PIN has a friendly error', () {
      expect(validateSpendWisePin(''), contains('Enter your PIN'));
    });
  });
}
