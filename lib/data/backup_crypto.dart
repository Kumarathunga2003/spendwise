import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'finance_snapshot.dart';

/// Portable passphrase-encrypted, authenticated SpendWise backup format.
/// Format v1: PBKDF2-HMAC-SHA256 + AES-256-GCM.
/// This protects an EXPORTED file; the installed SQLite DB itself is NOT encrypted.
class BackupCrypto {
  static const _format = 'spendwise-encrypted-backup-v1';
  static const _iterations = 350000;
  static const _maxBytes = 16 * 1024 * 1024;
  static final _aes = AesGcm.with256bits();

  static List<int> _randomBytes(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  static Future<Uint8List> encrypt(
      FinanceSnapshot snapshot, String password) async {
    _checkPassword(password);
    snapshot.validate();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final kdf =
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _iterations, bits: 256);
    final key =
        await kdf.deriveKeyFromPassword(password: password, nonce: salt);
    final encoded = utf8.encode(jsonEncode(snapshot.toJson()));
    if (encoded.length > _maxBytes) {
      throw const FormatException('Backup too large to export.');
    }
    final box = await _aes.encrypt(encoded,
        secretKey: key, nonce: nonce, aad: utf8.encode(_format));
    return Uint8List.fromList(utf8.encode(jsonEncode({
      'format': _format,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    })));
  }

  static Future<FinanceSnapshot> decrypt(
      Uint8List encodedFile, String password) async {
    if (encodedFile.isEmpty || encodedFile.length > _maxBytes) {
      throw const FormatException('Invalid or oversized SpendWise backup.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(encodedFile));
    } catch (_) {
      throw const FormatException(
          'This is not a valid encrypted SpendWise backup file.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _format ||
        decoded['kdf'] != 'PBKDF2-HMAC-SHA256') {
      throw const FormatException('Unsupported backup file format.');
    }
    final iterations = decoded['iterations'];
    if (iterations is! int || iterations < 100000 || iterations > 1500000) {
      throw const FormatException('Invalid backup key derivation settings.');
    }
    try {
      final salt = base64Decode(decoded['salt'] as String);
      final nonce = base64Decode(decoded['nonce'] as String);
      final cipherText = base64Decode(decoded['ciphertext'] as String);
      final mac = base64Decode(decoded['mac'] as String);
      if (salt.length != 16 ||
          nonce.length != 12 ||
          mac.length != 16 ||
          cipherText.length > _maxBytes) {
        throw const FormatException('Malformed encrypted backup.');
      }
      final kdf = Pbkdf2(
          macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
      final key =
          await kdf.deriveKeyFromPassword(password: password, nonce: salt);
      final clearText = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: utf8.encode(_format),
      );
      final plain = jsonDecode(utf8.decode(clearText));
      if (plain is! Map<String, dynamic>) {
        throw const FormatException('Invalid backup contents.');
      }
      return FinanceSnapshot.fromJson(plain);
    } catch (_) {
      throw const FormatException(
        'Cannot open backup. Check the passphrase and file integrity.',
      );
    }
  }

  static void _checkPassword(String value) {
    if (value.length < 12 || value.length > 256) {
      throw const FormatException(
          'Use a backup passphrase of at least 12 characters.');
    }
  }
}
