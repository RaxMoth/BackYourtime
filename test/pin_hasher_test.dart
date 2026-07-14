import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:unspend/core/security/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('save→verify round-trip: correct PIN matches, wrong PIN fails', () {
      const pin = '1234';
      final salt = PinHasher.generateSalt();
      final stored = PinHasher.hash(salt, pin);

      // Correct PIN with the same salt reproduces the stored hash.
      expect(PinHasher.hash(salt, pin), stored);
      // Wrong PIN does not.
      expect(PinHasher.hash(salt, '4321'), isNot(stored));
    });

    test('hash is deterministic for a fixed salt + pin', () {
      expect(PinHasher.hash('abc123', '0000'), PinHasher.hash('abc123', '0000'));
    });

    test('same PIN under different salts yields different hashes', () {
      expect(
        PinHasher.hash('saltone', '9999'),
        isNot(PinHasher.hash('salttwo', '9999')),
      );
    });

    test('hash is 64-char lowercase hex (SHA-256)', () {
      final h = PinHasher.hash('deadbeef', '1111');
      expect(h, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('generateSalt returns 32-char lowercase hex (16 bytes)', () {
      final salt = PinHasher.generateSalt();
      expect(salt, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('generateSalt is deterministic under a seeded Random', () {
      expect(PinHasher.generateSalt(Random(42)), PinHasher.generateSalt(Random(42)));
    });

    test('generateSalt produces distinct salts across calls', () {
      expect(PinHasher.generateSalt(), isNot(PinHasher.generateSalt()));
    });
  });
}
