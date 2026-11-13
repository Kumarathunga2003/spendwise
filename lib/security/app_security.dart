import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart'
    show FlutterPbkdf2;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN-only access control for SpendWise. Existing on-device PIN hashes and
/// salts remain compatible with the previous version (350,000 PBKDF2 rounds).
class AppLockException implements Exception {
  final String message;
  const AppLockException(this.message);
  @override
  String toString() => message;
}

String? validateSpendWisePin(String pin) {
  if (pin.isEmpty) return 'Enter your PIN to continue.';
  if (!RegExp(r'^\d+$').hasMatch(pin)) return 'Use numbers only.';
  if (pin.length < 6) return 'PIN must contain at least 6 digits.';
  if (pin.length > 12) return 'PIN cannot contain more than 12 digits.';
  return null;
}

class AppSecurity extends ChangeNotifier {
  static final AppSecurity instance = AppSecurity();
  final FlutterSecureStorage _secrets = const FlutterSecureStorage();

  static const _hashKey = 'sw.lock.pin.hash.v1';
  static const _saltKey = 'sw.lock.pin.salt.v1';
  static const _bioKey =
      'sw.lock.biometric.v1'; // Historical setting; never used.
  static const _minutesKey = 'sw.lock.idle.minutes';
  static const _failCountKey = 'sw.lock.failed.count.v1';
  static const _blockedKey = 'sw.lock.blocked.until.v1';

  bool ready = false;
  bool enabled = false;
  bool unlocked = true;
  int autoLockMinutes = 1;
  String? securityError;
  int _failed = 0;
  DateTime? _blockedUntil;
  DateTime _lastUsed = DateTime.now();
  List<int>? _cachedHash;
  List<int>? _cachedSalt;
  bool _checkingPin = false;

  Future<void> load() async {
    ready = false;
    try {
      final hashText = await _secrets.read(key: _hashKey);
      final saltText = await _secrets.read(key: _saltKey);
      if ((hashText == null) != (saltText == null)) {
        throw const AppLockException(
          'Your PIN settings are incomplete. Do not clear app data. Keep your verified encrypted backup.',
        );
      }
      _cachedHash = hashText == null ? null : base64Decode(hashText);
      _cachedSalt = saltText == null ? null : base64Decode(saltText);
      enabled = hashText != null;
      final minutes =
          int.tryParse(await _secrets.read(key: _minutesKey) ?? '1');
      autoLockMinutes = [0, 1, 5, 15].contains(minutes) ? minutes! : 1;
      _failed =
          int.tryParse(await _secrets.read(key: _failCountKey) ?? '0') ?? 0;
      final blocked = await _secrets.read(key: _blockedKey);
      _blockedUntil = blocked == null ? null : DateTime.tryParse(blocked);
      unlocked = !enabled;
      securityError = null;
    } catch (error) {
      // Fail closed when the Android keystore or PIN configuration fails.
      enabled = true;
      unlocked = false;
      _cachedHash = null;
      _cachedSalt = null;
      securityError = error is AppLockException
          ? error.message
          : 'Secure storage is unavailable. Restart your phone and try again. Do not clear app data.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<List<int>> _digest(String pin, List<int> salt) async {
    // Keep the exact same hash parameters so existing PINs still work.
    // Prefer Android's native PBKDF2 instead of slower pure-Dart hashing.
    const iterations = 350000;
    final fallback = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final algorithm = FlutterPbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
      fallback: fallback,
    );
    final secret = await algorithm.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return secret.extractBytes();
  }

  Future<bool> checkPin(String pin) async {
    if (_checkingPin) {
      throw const AppLockException('PIN verification is already in progress.');
    }
    if (securityError != null) throw AppLockException(securityError!);
    if (_blockedUntil != null && DateTime.now().isBefore(_blockedUntil!)) {
      final remaining = _blockedUntil!.difference(DateTime.now()).inSeconds;
      throw AppLockException(
          'Too many incorrect PINs. Try again in ${remaining + 1} seconds.');
    }
    final validation = validateSpendWisePin(pin);
    if (validation != null) throw AppLockException(validation);
    final hash = _cachedHash;
    final salt = _cachedSalt;
    if (hash == null || salt == null || !enabled) {
      throw const AppLockException(
          'Saved PIN unavailable. Do not clear app data.');
    }
    _checkingPin = true;
    try {
      if (_blockedUntil != null) {
        _blockedUntil = null;
        _failed = 0;
        await _resetFailures();
      }
      final candidate = await _digest(pin, salt);
      var difference = candidate.length ^ hash.length;
      for (var i = 0; i < candidate.length && i < hash.length; i++) {
        difference |= candidate[i] ^ hash[i];
      }
      if (difference == 0) {
        final hadFailures = _failed != 0 || _blockedUntil != null;
        _failed = 0;
        _blockedUntil = null;
        unlocked = true;
        touch();
        notifyListeners(); // Show the dashboard before optional secure-storage cleanup.
        if (hadFailures) {
          try {
            await _resetFailures();
          } catch (_) {
            // Session is unlocked with the correct PIN; show an error if the
            // secure keystore can't clear the failure counter next time.
          }
        }
        return true;
      }
      _failed++;
      if (_failed >= 5) {
        _blockedUntil = DateTime.now().add(const Duration(minutes: 2));
        _failed = 0;
        await _secrets.write(
            key: _blockedKey, value: _blockedUntil!.toIso8601String());
        await _secrets.delete(key: _failCountKey);
        throw const AppLockException(
            'Too many attempts. Try again in 2 minutes.');
      }
      await _secrets.write(key: _failCountKey, value: '$_failed');
      return false;
    } finally {
      _checkingPin = false;
    }
  }

  Future<void> _resetFailures() async {
    await _secrets.delete(key: _failCountKey);
    await _secrets.delete(key: _blockedKey);
  }

  Future<void> createPin(String pin, {String? currentPin}) async {
    final problem = validateSpendWisePin(pin);
    if (problem != null) throw AppLockException(problem);
    if (enabled) {
      if (currentPin == null || currentPin.isEmpty) {
        throw const AppLockException('Enter your current PIN to change it.');
      }
      if (!await checkPin(currentPin)) {
        throw const AppLockException('Current PIN is incorrect.');
      }
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await _digest(pin, salt);
    // Preserve original PIN if either secure write fails.
    final previousSalt = await _secrets.read(key: _saltKey);
    final previousHash = await _secrets.read(key: _hashKey);
    try {
      await _secrets.write(key: _saltKey, value: base64Encode(salt));
      await _secrets.write(key: _hashKey, value: base64Encode(hash));
    } catch (_) {
      try {
        if (previousSalt == null) {
          await _secrets.delete(key: _saltKey);
        } else {
          await _secrets.write(key: _saltKey, value: previousSalt);
        }
        if (previousHash == null) {
          await _secrets.delete(key: _hashKey);
        } else {
          await _secrets.write(key: _hashKey, value: previousHash);
        }
      } catch (_) {
        throw const AppLockException(
            'PIN update failed. The old PIN could not be restored. Keep your encrypted backup.');
      }
      throw const AppLockException('Could not save your PIN. Try again.');
    }
    _cachedSalt = salt;
    _cachedHash = hash;
    enabled = true;
    unlocked = true;
    _failed = 0;
    _blockedUntil = null;
    await _resetFailures();
    touch();
    notifyListeners();
  }

  Future<void> disable(String currentPin) async {
    if (!await checkPin(currentPin)) {
      throw const AppLockException('Incorrect current PIN.');
    }
    for (final key in [
      _hashKey,
      _saltKey,
      _bioKey,
      _failCountKey,
      _blockedKey
    ]) {
      await _secrets.delete(key: key);
    }
    _cachedHash = null;
    _cachedSalt = null;
    enabled = false;
    unlocked = true;
    _failed = 0;
    _blockedUntil = null;
    notifyListeners();
  }

  Future<void> clearLockSettings() async {
    for (final key in [
      _hashKey,
      _saltKey,
      _bioKey,
      _minutesKey,
      _failCountKey,
      _blockedKey,
    ]) {
      await _secrets.delete(key: key);
    }
    _cachedHash = null;
    _cachedSalt = null;
    enabled = false;
    unlocked = true;
    securityError = null;
    _failed = 0;
    _blockedUntil = null;
    autoLockMinutes = 1;
    notifyListeners();
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    if (![0, 1, 5, 15].contains(minutes)) {
      throw const AppLockException('Choose a supported auto-lock time.');
    }
    await _secrets.write(key: _minutesKey, value: '$minutes');
    autoLockMinutes = minutes;
    notifyListeners();
  }

  void touch() => _lastUsed = DateTime.now();

  void checkForegroundTimeout() {
    if (!enabled || !unlocked || autoLockMinutes == 0) return;
    if (DateTime.now().difference(_lastUsed) >=
        Duration(minutes: autoLockMinutes)) {
      lock();
    }
  }

  void onPause() {
    _lastUsed = DateTime.now();
    if (enabled && autoLockMinutes == 0) lock();
  }

  void onResume() {
    if (!enabled || !unlocked) return;
    if (autoLockMinutes == 0 ||
        DateTime.now().difference(_lastUsed) >=
            Duration(minutes: autoLockMinutes)) {
      lock();
    }
  }

  void lock() {
    if (!enabled) return;
    unlocked = false;
    notifyListeners();
  }
}
