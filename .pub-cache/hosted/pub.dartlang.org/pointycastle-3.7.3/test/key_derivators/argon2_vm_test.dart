@OnPlatform({
  'chrome': Skip('Excessive time / resource consumption on this platform'),
  'node': Skip('Excessive time / resource consumption on this platform')
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

  group('Argon2BytesGenerator -- non-js platforms', () {
    /* Multiple test cases for various input values */
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
    // A memory-cosing test, will fail on Web platform.
    test('Argon2 Test 2', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_10,
          2,
          20,
          'password',
          'somesalt',
          '9690ec55d28d3ed32562f2e73ea62b02b018757643a2ae6e79528459de8106e9',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout, onPlatform: {
      'chrome': Skip('Due to high memory occupation, Chrome will die.'),
    });
    test('Argon2 Test 3', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_10,
          2,
          16,
          'password',
          'diffsalt',
          '79a103b90fe8aef8570cb31fc8b22259778916f8336b7bdac3892569d4f1c497',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout);

    test('Argon2 Test 4', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_10,
          2,
          16,
          'password',
          'diffsalt',
          '1a097a5d1c80e579583f6e19c7e4763ccb7c522ca85b7d58143738e12ca39f8e6e42734c950ff2463675b97c37ba'
              '39feba4a9cd9cc5b4c798f2aaf70eb4bd044c8d148decb569870dbd923430b82a083f284beae777812cce18cdac68ee8ccef'
              'c6ec9789f30a6b5a034591f51af830f4',
          112);
    }, timeout: timeout);
    test('Argon2 Test 5', () {
      /* Multiple test cases for various input values */
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_13,
          2,
          16,
          'password',
          'somesalt',
          'c1628832147d9720c5bd1cfd61367078729f6dfb6f8fea9ff98158e0d7816ed0',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout);
    test('Argon2 Test 6', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_13,
          2,
          20,
          'password',
          'somesalt',
          'd1587aca0922c3b5d6a83edab31bee3c4ebaef342ed6127a55d19b2351ad1f41',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout, onPlatform: {
      'chrome': Skip('Due to high memory occupation, Chrome will die.'),
    });
    test('Argon2 Test 7', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_13,
          2,
          18,
          'password',
          'somesalt',
          '296dbae80b807cdceaad44ae741b506f14db0959267b183b118f9b24229bc7cb',
          DEFAULT_OUTPUTLEN);
    }, timeout: timeout);
    test('Argon2 Test 8', () {
      _hashTest(
          Argon2Parameters.ARGON2_VERSION_13,
          2,
          8,
          'password',
          'somesalt',
          '89e9029f4637b295beb027056a7336c414fadd43f6b208645281cb214a56452f',
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
