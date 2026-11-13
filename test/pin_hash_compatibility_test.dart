import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SpendWise PIN hash remains compatible', () async {
    // Fixed test data, not a real user's PIN.
    final salt = List<int>.generate(
      16,
      (index) => index,
    );

    // Keep the original SpendWise hashing settings.
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 350000,
      bits: 256,
    );

    final secret = await algorithm.deriveKeyFromPassword(
      password: '123456',
      nonce: salt,
    );

    final actual = base64Encode(
      await secret.extractBytes(),
    );

    // Expected hash for the fixed test data.
    expect(
      actual,
      '04GU+tvLinMg83dP+GhG9G81MoWQYt5v4uHTWiRLMVA=',
    );
  });
}
