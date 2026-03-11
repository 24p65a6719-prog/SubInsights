import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';

/// Wraps [FlutterSecureStorage] with an HMAC integrity layer.
///
/// Every value is stored as `payload|hmac`.  On read the HMAC is verified
/// so tampered data is rejected.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // HMAC key derived once per install — stored inside secure storage itself.
  static const _hmacKeySlot = '__hmac_key__';
  static String? _hmacKey;

  /// Ensure the per-device HMAC key exists.
  static Future<void> _ensureKey() async {
    if (_hmacKey != null) return;
    _hmacKey = await _storage.read(key: _hmacKeySlot);
    if (_hmacKey == null) {
      _hmacKey = base64Encode(CryptoService.randomBytes(32));
      await _storage.write(key: _hmacKeySlot, value: _hmacKey!);
    }
  }

  /// Write a value with integrity protection.
  static Future<void> write(String key, String value) async {
    await _ensureKey();
    final mac = CryptoService.hmacSign(value, _hmacKey!);
    await _storage.write(key: key, value: '$value|$mac');
  }

  /// Read and verify integrity. Returns `null` if missing or tampered.
  static Future<String?> read(String key) async {
    await _ensureKey();
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    final idx = raw.lastIndexOf('|');
    if (idx == -1) return null;
    final value = raw.substring(0, idx);
    final mac = raw.substring(idx + 1);
    if (CryptoService.hmacSign(value, _hmacKey!) != mac) {
      debugPrint('SecureStorage integrity check failed for key "$key"');
      await _storage.delete(key: key);
      return null;
    }
    return value;
  }

  /// Delete a key.
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Write a JSON-serialisable map.
  static Future<void> writeJson(String key, Map<String, dynamic> data) =>
      write(key, json.encode(data));

  /// Read previously-stored JSON map.
  static Future<Map<String, dynamic>?> readJson(String key) async {
    final v = await read(key);
    if (v == null) return null;
    try {
      return json.decode(v) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
