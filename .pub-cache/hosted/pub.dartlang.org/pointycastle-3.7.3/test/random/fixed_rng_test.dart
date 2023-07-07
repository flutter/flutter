library test.random.fixed_rng_test.dart;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:test/test.dart';

import '../test/src/fixed_secure_random.dart';

void main() {
  group('FixedSecureRandom:', () {
    test('No seed', () {
      final rng = FixedSecureRandom();
      try {
        rng.nextUint8();
        fail('expected StateError from uninitialized FixedSecureRandom');
      } on StateError catch (e) {
        expect(e.message, 'fixed secure random has no values');
      }
    });

    test('Seed Exhaustion', () {
      final rng = FixedSecureRandom();
      rng.seed(KeyParameter(Uint8List.fromList([1, 2])));
      try {
        expect(rng.nextUint8(), 1);
        expect(rng.nextUint8(), 2);
        rng.nextUint8();
        fail('expected StateError from running out of entropy');
      } on StateError catch (e) {
        expect(e.message, 'fixed secure random unexpectedly exhausted');
      }
    });
  });
}
