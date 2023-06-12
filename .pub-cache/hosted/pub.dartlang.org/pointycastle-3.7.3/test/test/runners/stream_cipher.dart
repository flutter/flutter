// See file LICENSE for more information.

library test.test.stream_cipher_tests;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runStreamCipherTests(StreamCipher cipher, CipherParameters params,
    List<String> plainCipherTextPairs) {
  group('${cipher.algorithmName}:', () {
    group('cipher  :', () {
      for (var i = 0; i < plainCipherTextPairs.length; i += 2) {
        var plainText = plainCipherTextPairs[i];
        var cipherText = plainCipherTextPairs[i + 1];

        test('${formatAsTruncated(plainText)}',
            () => _runStreamCipherTest(cipher, params, plainText, cipherText));
      }
    });

    group('decipher:', () {
      for (var i = 0; i < plainCipherTextPairs.length; i += 2) {
        var plainText = plainCipherTextPairs[i];
        var cipherText = plainCipherTextPairs[i + 1];

        test(
            '${formatAsTruncated(plainText)}',
            () =>
                _runStreamDecipherTest(cipher, params, cipherText, plainText));
      }
    });

    group('ciph&dec:', () {
      var plainText = createUint8ListFromSequentialNumbers(1021);
      test('~1KB of sequential bytes',
          () => _runStreamCipherDecipherTest(cipher, params, plainText));
    });
  });
}

void _resetCipher(
    StreamCipher cipher, bool forEncryption, CipherParameters params) {
  cipher
    ..reset()
    ..init(forEncryption, params);
}

void _runStreamCipherTest(StreamCipher cipher, CipherParameters params,
    String plainTextString, String expectedHexCipherText) {
  _resetCipher(cipher, true, params);

  var plainText = createUint8ListFromString(plainTextString);
  var cipherText = cipher.process(plainText);
  var hexCipherText = formatBytesAsHexString(cipherText);

  expect(hexCipherText, equals(expectedHexCipherText));
}

void _runStreamDecipherTest(StreamCipher cipher, CipherParameters params,
    String hexCipherText, String expectedPlainText) {
  _resetCipher(cipher, false, params);

  var cipherText = createUint8ListFromHexString(hexCipherText);
  var plainText = cipher.process(cipherText);

  expect(String.fromCharCodes(plainText), equals(expectedPlainText));
}

void _runStreamCipherDecipherTest(
    StreamCipher cipher, CipherParameters params, Uint8List plainText) {
  _resetCipher(cipher, true, params);
  var cipherText = cipher.process(plainText);

  _resetCipher(cipher, false, params);
  var plainTextAgain = cipher.process(cipherText);

  expect(plainTextAgain, equals(plainText));
}
