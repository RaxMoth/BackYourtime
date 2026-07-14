import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Pure, storage-independent PIN hashing helpers.
///
/// Extracted from `ProfilesNotifier` so the hash formula can be unit-tested
/// without a Keychain / `flutter_secure_storage` mock. Behaviour is identical
/// to the original inline implementation: hex SHA-256 over `'<salt>:<pin>'`.
class PinHasher {
  const PinHasher._();

  /// Generates a random 16-byte salt as a lowercase hex string (32 chars).
  ///
  /// Pass a seeded [random] in tests for determinism; production callers omit
  /// it to get a cryptographically secure salt via [Random.secure].
  static String generateSalt([Random? random]) {
    final rng = random ?? Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes [pin] with [salt] using SHA-256 over `'<salt>:<pin>'`.
  static String hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
