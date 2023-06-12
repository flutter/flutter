@OnPlatform({
  'vm': Skip(),
})
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

const int DEFAULT_OUTPUTLEN = 32;

/// First ported to Dart by Graciliano M. Passos:
/// - https://pub.dev/packages/argon2
/// - https://github.com/gmpassos/argon2
///
/// The linked project was adapted for the purposes of this project, since it
/// is a 1:1 port of BouncyCastle's Java implementation.
void main() {
  final timeout = Timeout.parse("15m");

  group('Argon2BytesGenerator - non dart vm', () {
    //
    // This is more of a sanity test on js platforms.
    // The full battery of tests, has been observed to run some JS platforms
    // out of memory and it is very very slow.
    //
    test('Argon2 Test 1', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_10,
          2,
          16,
          'password',
          'somesalt',
          'f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout);
  });
}

void _hashTest(int version, int iterations, int memoryPowerOf2, String password,
    String salt, String passwordRef, int outputLength) {
  var parameters = Argon2Parameters(
    Argon2Parameters.ARGON2_i,
    latin1.encode(salt),
    desiredKeyLength: outputLength,
    version: version,
    iterations: iterations,
    memoryPowerOf2: memoryPowerOf2,
  );

  var gen = Argon2BytesGenerator();
  gen.init(parameters);

  var passwordBytes = Uint8List.fromList(utf8.encode(password));

  var result = gen.process(passwordBytes);

  expect(result, createUint8ListFromHexString(passwordRef));

  // Should be able to re-use generator after successful use
  result = gen.process(passwordBytes);
  expect(result, createUint8ListFromHexString(passwordRef));
}
