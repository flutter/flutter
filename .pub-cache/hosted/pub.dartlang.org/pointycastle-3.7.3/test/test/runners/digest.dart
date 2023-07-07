// See file LICENSE for more information.

library test.test.digest_tests;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runDigestTests(Digest digest, List<String> plainDigestTextPairs) {
  group('${digest.algorithmName}:', () {
    group('digest:', () {
      for (var i = 0; i < plainDigestTextPairs.length; i += 2) {
        var plainText = plainDigestTextPairs[i];
        var digestText = plainDigestTextPairs[i + 1];

        test('${formatAsTruncated(plainText)}',
            () => _runDigestTest(digest, plainText, digestText));
      }
    });
  });
}

void _runDigestTest(
    Digest digest, String plainTextString, String expectedHexDigestText) {
  digest.reset();

  var plainText = createUint8ListFromString(plainTextString);
  var out = digest.process(plainText);
  var hexOut = formatBytesAsHexString(out);

  expect(hexOut, equals(expectedHexDigestText));

  for (var i = 0; i < plainText.length; ++i) {
    digest.updateByte(plainText[i]);
  }
  out = Uint8List(digest.digestSize);

  digest.doFinal(out, 0);
  hexOut = formatBytesAsHexString(out);

  expect(hexOut, equals(expectedHexDigestText));
}
