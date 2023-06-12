// See file LICENSE for more information.

library test.key_derivators.hkdf_test;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/hkdf.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/runners/key_derivators.dart';
import '../test/src/helpers.dart';

void main() {
  group('HKDF tests', () {
    group('derivator tests', () {
      var ikm = createUint8ListFromString('initial key material');
      var salt = createUint8ListFromString('salt');
      var params = HkdfParameters(ikm, 32, salt);
      var hkdf = KeyDerivator('SHA-256/HKDF');

      runKeyDerivatorTests(hkdf, [
        params,
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
        '013133aa211d145cbd3f1377259d555c46a9d8a4b04371b9f79b3c9f37c20f9d',
        params,
        'En un lugar de La Mancha, de cuyo nombre no quiero acordarme...',
        'df6d2879dddf56f373e8d052147dbdafe2c7bdfb26ee425a9d5b39587dbe7e0e',
      ]);
    });

    // HKDF tests - vectors from RFC 5869
    group('Test vectors - RFC 5869', () {
      test('Test Case 1 - Basic test case with SHA-256', () {
        var ikm = createUint8ListFromHexString(
            '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b');
        var salt = createUint8ListFromHexString('000102030405060708090a0b0c');
        var info = createUint8ListFromHexString('f0f1f2f3f4f5f6f7f8f9');
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, salt, info);

        var hkdf = HKDFKeyDerivator(SHA256Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected =
            '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865';
        expect(actual, equals(expected));
      });

      test('Test Case 2 - Test with SHA-256 and longer inputs/outputs', () {
        var ikm =
            createUint8ListFromHexString('000102030405060708090a0b0c0d0e0f'
                '101112131415161718191a1b1c1d1e1f'
                '202122232425262728292a2b2c2d2e2f'
                '303132333435363738393a3b3c3d3e3f'
                '404142434445464748494a4b4c4d4e4f');
        var salt =
            createUint8ListFromHexString('606162636465666768696a6b6c6d6e6f'
                '707172737475767778797a7b7c7d7e7f'
                '808182838485868788898a8b8c8d8e8f'
                '909192939495969798999a9b9c9d9e9f'
                'a0a1a2a3a4a5a6a7a8a9aaabacadaeaf');
        var info =
            createUint8ListFromHexString('b0b1b2b3b4b5b6b7b8b9babbbcbdbebf'
                'c0c1c2c3c4c5c6c7c8c9cacbcccdcecf'
                'd0d1d2d3d4d5d6d7d8d9dadbdcdddedf'
                'e0e1e2e3e4e5e6e7e8e9eaebecedeeef'
                'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff');
        var l = 82;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, salt, info);

        var hkdf = HKDFKeyDerivator(SHA256Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected = 'b11e398dc80327a1c8e7f78c596a4934'
            '4f012eda2d4efad8a050cc4c19afa97c'
            '59045a99cac7827271cb41c65e590e09'
            'da3275600c2f09b8367793a9aca3db71'
            'cc30c58179ec3e87c14c01d5c1f3434f'
            '1d87';
        expect(actual, equals(expected));
      });

      // setting salt to an empty byte array means that the salt is set to
      // HashLen zero valued bytes
      // setting info to null generates an empty byte array as info
      // structure
      test('Test Case 3 - Test with SHA-256 and zero-length salt/info', () {
        var ikm = createUint8ListFromHexString(
            '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b');
        var salt = Uint8List(0);
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, salt, null);

        var hkdf = HKDFKeyDerivator(SHA256Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected = '8da4e775a563c18f715f802a063c5a31'
            'b8a11f5c5ee1879ec3454e5f3c738d2d'
            '9d201395faa4b61a96c8';
        expect(actual, equals(expected));
      });

      test('Test Case 4 - Basic test case with SHA-1', () {
        var ikm = createUint8ListFromHexString('0b0b0b0b0b0b0b0b0b0b0b');
        var salt = createUint8ListFromHexString('000102030405060708090a0b0c');
        var info = createUint8ListFromHexString('f0f1f2f3f4f5f6f7f8f9');
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, salt, info);

        var hkdf = HKDFKeyDerivator(SHA1Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected = '085a01ea1b10f36933068b56efa5ad81'
            'a4f14b822f5b091568a9cdd4f155fda2'
            'c22e422478d305f3f896';
        expect(actual, equals(expected));
      });

      test('Test Case 5 - Test with SHA-1 and longer inputs/outputs', () {
        var ikm = createUint8ListFromHexString(
            '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f');
        var salt = createUint8ListFromHexString(
            '606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf');
        var info = createUint8ListFromHexString(
            'b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff');
        var l = 82;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, salt, info);

        var hkdf = HKDFKeyDerivator(SHA1Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected =
            '0bd770a74d1160f7c9f12cd5912a06ebff6adcae899d92191fe4305673ba2ffe8fa3f1a4e5ad79f3f334b3b202b2173c486ea37ce3d397ed034c7f9dfeb15c5e927336d0441f4c4300e2cff0d0900b52d3b4';
        expect(actual, equals(expected));
      });

      // setting salt to null should generate a salt of HashLen zero valued bytes
      test('Test Case 6 - Test with SHA-1 and zero-length salt/info', () {
        var ikm = createUint8ListFromHexString(
            '0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b');
        var info = Uint8List(0);
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, null, info);

        var hkdf = HKDFKeyDerivator(SHA1Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected =
            '0ac1af7002b3d761d1e55298da9d0506b9ae52057220a306e07b6b87e8df21d0ea00033de03984d34918';
        expect(actual, equals(expected));
      });

      // this test is identical to test 6 in all ways bar the IKM value
      test('Test Case 7 - Test with SHA-1, salt not provided, zero-length info',
          () {
        var ikm = createUint8ListFromHexString(
            '0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c');
        var info = Uint8List(0);
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, null, info);

        var hkdf = HKDFKeyDerivator(SHA1Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected =
            '2c91117204d745f3500d636a62f64f0ab3bae548aa53d423b0d1f27ebba6f5e5673a081d70cce7acfc48';
        expect(actual, equals(expected));
      });

      // this test is identical to test 7 in all ways bar the IKM value
      // which is set to the PRK value
      test(
          'Additional Test Case - Test with SHA-1, skipping extract zero-length info',
          () {
        var ikm = createUint8ListFromHexString(
            '2adccada18779e7c2077ad2eb19d3f3e731385dd');
        var info = Uint8List(0);
        var l = 42;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, null, info, true);

        var hkdf = HKDFKeyDerivator(SHA1Digest());
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var actual = formatBytesAsHexString(okm);
        var expected =
            '2c91117204d745f3500d636a62f64f0ab3bae548aa53d423b0d1f27ebba6f5e5673a081d70cce7acfc48';
        expect(actual, equals(expected));
      });

      // this test is identical to test 7 in all ways bar the IKM value
      test('Additional Test Case - Test with SHA-1, maximum output', () {
        var hash = SHA1Digest();
        var ikm = createUint8ListFromHexString(
            '2adccada18779e7c2077ad2eb19d3f3e731385dd');
        var info = Uint8List(0);
        var l = 255 * hash.digestSize;
        var okm = Uint8List(l);

        var params = HkdfParameters(ikm, l, null, info, true);

        var hkdf = HKDFKeyDerivator(hash);
        hkdf.init(params);
        hkdf.deriveKey(null, 0, okm, 0);

        var zeros = 0;
        for (var i = 0; i < hash.digestSize; i++) {
          if (okm[i] == 0) {
            zeros++;
          }
        }

        if (zeros == hash.digestSize) {
          fail('HKDF failed generator test A.102');
        }
      });
    });
  });
}
