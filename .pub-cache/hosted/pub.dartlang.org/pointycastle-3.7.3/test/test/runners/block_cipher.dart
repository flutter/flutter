// See file LICENSE for more information.

library test.test.block_cipher_tests;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runBlockCipherTests(BlockCipher cipher, CipherParameters? params,
    List<String> plainCipherTextPairs) {
  group('${cipher.algorithmName}:', () {
    group('cipher  :', () {
      for (var i = 0; i < plainCipherTextPairs.length; i += 2) {
        var plainText = plainCipherTextPairs[i];
        var cipherText = plainCipherTextPairs[i + 1];

        test('${formatAsTruncated(plainText)}',
            () => _runBlockCipherTest(cipher, params, plainText, cipherText));
      }
    });

    group('decipher:', () {
      for (var i = 0; i < plainCipherTextPairs.length; i += 2) {
        var plainText = plainCipherTextPairs[i];
        var cipherText = plainCipherTextPairs[i + 1];

        test('${formatAsTruncated(plainText)}',
            () => _runBlockDecipherTest(cipher, params, cipherText, plainText));
      }
    });

    group('ciph&dec:', () {
      var plainText = createUint8ListFromSequentialNumbers(1024);
      test('1KB of sequential bytes',
          () => _runBlockCipherDecipherTest(cipher, params, plainText));
    });
  });
}

void _resetCipher(
    BlockCipher cipher, bool forEncryption, CipherParameters? params) {
  cipher
    ..reset()
    ..init(forEncryption, params);
}

void _runBlockCipherTest(BlockCipher cipher, CipherParameters? params,
    String plainTextString, String expectedHexCipherText) {
  var plainText = createUint8ListFromString(plainTextString);

  _resetCipher(cipher, true, params);
  var cipherText = _processBlocks(cipher, plainText);
  var hexCipherText = formatBytesAsHexString(cipherText);

  expect(hexCipherText, equals(expectedHexCipherText));
}

void _runBlockDecipherTest(BlockCipher cipher, CipherParameters? params,
    String hexCipherText, String expectedPlainText) {
  var cipherText = createUint8ListFromHexString(hexCipherText);

  _resetCipher(cipher, false, params);
  var plainText = _processBlocks(cipher, cipherText);

  expect(String.fromCharCodes(plainText), equals(expectedPlainText));
}

void _runBlockCipherDecipherTest(
    BlockCipher cipher, CipherParameters? params, Uint8List plainText) {
  _resetCipher(cipher, true, params);
  var cipherText = _processBlocks(cipher, plainText);

  _resetCipher(cipher, false, params);
  var plainTextAgain = _processBlocks(cipher, cipherText);

  expect(plainTextAgain, equals(plainText));
}

Uint8List _processBlocks(BlockCipher cipher, Uint8List inp) {
  var out = Uint8List(inp.lengthInBytes);
  for (var offset = 0; offset < inp.lengthInBytes;) {
    var len = cipher.processBlock(inp, offset, out, offset);
    offset += len;
    _assertRemainingBufferIsZero(out, offset);
  }
  return out;
}

void _assertRemainingBufferIsZero(Uint8List out, int offset) {
  if (offset < out.lengthInBytes) {
    expect(out.sublist(offset), isAllZeros);
  }
}
