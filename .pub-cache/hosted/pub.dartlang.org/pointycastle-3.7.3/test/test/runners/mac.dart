// See file LICENSE for more information.

library test.test.mac_tests;

import 'dart:typed_data' show Uint8List;

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

class PlainTextDigestPair {
  PlainTextDigestPair(this.plainText, this.hexDigestText);

  final Uint8List plainText;
  final String hexDigestText;
}

void runMacTests(Mac mac, List<PlainTextDigestPair> plainDigestTextPairs) {
  group('${mac.algorithmName}:', () {
    group('digest:', () {
      for (var i = 0; i < plainDigestTextPairs.length; i++) {
        var plainText = plainDigestTextPairs[i].plainText;
        var digestText = plainDigestTextPairs[i].hexDigestText;

        test('${formatAsTruncated(plainText.toString())}',
            () => _runMacTest(mac, plainText, digestText));
      }
    });
  });
}

void _runMacTest(Mac mac, Uint8List plainText, String expectedHexDigestText) {
  mac.reset();

  var out = mac.process(plainText);
  var hexOut = formatBytesAsHexString(out);

  expect(hexOut, equals(expectedHexDigestText));
}

/// HMAC tests with test vectors from a single test case in
/// [RFC 4231](https://tools.ietf.org/html/rfc4231) _Identifiers and Test
/// Vectors for HMAC-SHA-224, HMAC-SHA-256, HMAC-SHA-384, and HMAC-SHA-512_.

class Rfc4231TestVector {
  Rfc4231TestVector(this.name, this.keyHex, this.dataHex, this.hmacSha224,
      this.hmacSha256, this.hmacSha384, this.hmacSha512,
      {this.truncate128 = false});

  final String name;
  final String keyHex;
  final String dataHex;
  final String hmacSha224;
  final String hmacSha256;
  final String hmacSha384;
  final String hmacSha512;
  final bool truncate128;

  void run() {
    final key = createUint8ListFromHexString(keyHex);
    final data = createUint8ListFromHexString(dataHex);

    group(name, () {
      // For the blockLengths to use, see _DIGEST_BLOCK_LENGTH in the HMAC class
      _hmacTest('SHA-224/HMAC', key, data, hmacSha224, truncate128);
      _hmacTest('SHA-256/HMAC', key, data, hmacSha256, truncate128);
      _hmacTest('SHA-384/HMAC', key, data, hmacSha384, truncate128);
      _hmacTest('SHA-512/HMAC', key, data, hmacSha512, truncate128);
    });
  }

  void _hmacTest(String hmacName, Uint8List key, Uint8List data,
      String expected, bool truncate128) {
    test(hmacName, () {
      final hmac = Mac(hmacName)..init(KeyParameter(key));

      final d = hmac.process(data);

      final result =
          formatBytesAsHexString(((truncate128)) ? d.sublist(0, 16) : d);
      //print('$testName: $result');
      expect(result, equals(expected));
    });
  }

  static void runAll(Iterable<Rfc4231TestVector> testCases) {
    group('Tests from RFC 4231', () {
      for (final t in testCases) {
        t.run();
      }
    });
  }
}
