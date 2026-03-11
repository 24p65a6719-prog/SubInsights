import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Encryption & hashing utilities.
///
/// Uses PBKDF2 (100 000 iterations, SHA-256) for password hashing and
/// HMAC-SHA256 for data integrity.  Pure Dart — no native dependencies.
class CryptoService {
  CryptoService._();

  static final _secureRandom = Random.secure();

  /// Generate cryptographically-secure random bytes.
  static Uint8List randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  /// Generate a random 32-byte salt encoded as base64.
  static String generateSalt() => base64Encode(randomBytes(32));

  /// PBKDF2-HMAC-SHA256 key derivation.
  static Uint8List pbkdf2({
    required String password,
    required Uint8List salt,
    int iterations = 100000,
    int keyLength = 32,
  }) {
    final hmacSha256 = Hmac(sha256, utf8.encode(password));
    final blocks = (keyLength / 32).ceil();
    final result = BytesBuilder();

    for (var i = 1; i <= blocks; i++) {
      final blockBytes = ByteData(4)..setUint32(0, i);
      var u = hmacSha256
          .convert([...salt, ...blockBytes.buffer.asUint8List()]).bytes;
      var xor = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = Hmac(sha256, utf8.encode(password)).convert(u).bytes;
        for (var k = 0; k < xor.length; k++) {
          xor[k] ^= u[k];
        }
      }
      result.add(xor);
    }

    return Uint8List.fromList(result.toBytes().sublist(0, keyLength));
  }

  /// Hash a password with PBKDF2 and return `salt:hash` base64 string.
  static String hashPassword(String password) {
    final salt = randomBytes(32);
    final derived = pbkdf2(password: password, salt: salt);
    return '${base64Encode(salt)}:${base64Encode(derived)}';
  }

  /// Verify a password against a previously-produced `salt:hash` string.
  static bool verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = base64Decode(parts[0]);
    final expectedHash = parts[1];
    final derived = pbkdf2(password: password, salt: Uint8List.fromList(salt));
    return base64Encode(derived) == expectedHash;
  }

  /// Generate a cryptographic session token (URL-safe base64, 32 bytes).
  static String generateSessionToken() =>
      base64Url.encode(randomBytes(32));

  /// HMAC-SHA256 signature of arbitrary data.
  static String hmacSign(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }
}
