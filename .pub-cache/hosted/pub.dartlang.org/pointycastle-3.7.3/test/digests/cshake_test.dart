import 'dart:typed_data';

import 'package:pointycastle/digests/cshake.dart';
import 'package:pointycastle/digests/shake.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  performTest();
  performZeroPadTest();
  performDoFinalTest();
  testCSHAKESizeEnforcement();

  var empty = Uint8List(0);

  group('misc cshake', () {
    test('cshake / shake equality', () {
      checkSHAKE(128, CSHAKEDigest(128, Uint8List(0), empty),
          createUint8ListFromHexString('eeaabeef'));
      checkSHAKE(256, CSHAKEDigest(256, empty, null),
          createUint8ListFromHexString('eeaabeef'));
      checkSHAKE(128, CSHAKEDigest(128, null, empty),
          createUint8ListFromHexString('eeaabeef'));
      checkSHAKE(128, CSHAKEDigest(128, null, null),
          createUint8ListFromHexString('eeaabeef'));
      checkSHAKE(256, CSHAKEDigest(256, null, null),
          createUint8ListFromHexString('eeaabeef'));
    });
  });
}

String formatBytesAsHexString(Uint8List bytes) {
  var result = StringBuffer();
  for (var i = 0; i < bytes.lengthInBytes; i++) {
    var part = bytes[i];
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

void checkSHAKE(int bitSize, CSHAKEDigest cshake, Uint8List msg) {
  var ref = SHAKEDigest(bitSize);

  ref.update(msg, 0, msg.length);
  cshake.update(msg, 0, msg.length);

  var res1 = Uint8List(32);
  var res2 = Uint8List(32);

  ref.doFinalRange(res1, 0, res1.length);
  cshake.doFinalRange(res2, 0, res2.length);

  expect(res1, equals(res2));
}

void performDoFinalTest() {
  group('CSHAKE doFinalTest', () {
    test('doOutput no change on update until doFinal', () {
      var cshake = CSHAKEDigest(
          128, Uint8List(0), Uint8List.fromList('Email Signature'.codeUnits));
      cshake.update(createUint8ListFromHexString('00010203'), 0, 4);
      var res = Uint8List(32);
      cshake.doOutput(res, 0, res.length);
      expect(
          res,
          equals(createUint8ListFromHexString(
              'c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5')));

      cshake.doOutput(res, 0, res.length);

      expect(
          res,
          isNot(createUint8ListFromHexString(
              'c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5')));

      cshake.doFinalRange(res, 0, res.length);

      cshake.update(createUint8ListFromHexString('00010203'), 0, 4);

      cshake.doFinalRange(res, 0, res.length);

      expect(
          res,
          equals(createUint8ListFromHexString(
              'c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5')));

      cshake.update(createUint8ListFromHexString('00010203'), 0, 4);

      cshake.doOutput(res, 0, res.length);

      expect(
          res,
          equals(createUint8ListFromHexString(
              'c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5')));

      cshake.doFinalRange(res, 0, res.length);

      expect(
          res,
          equals(createUint8ListFromHexString(
              '9cbce830079c452abdeb875366a49ebfe75b89ef17396e34898e904830b0e136')));
    });
  });
}

void performZeroPadTest() {
  group('CSHAKE checkZeroPadZ', () {
    test('256 no function name (N)', () {
      var buf = Uint8List(20);
      var cshake1 = CSHAKEDigest(256, Uint8List(0), Uint8List(265));
      cshake1.doOutput(buf, 0, buf.length);
      expect(
          buf,
          equals(createUint8ListFromHexString(
              '6e393540387004f087c4180db008acf6825190cf')));
    });

    test('128 no function name (N)', () {
      var buf = Uint8List(20);
      var cshake1 = CSHAKEDigest(128, Uint8List(0), Uint8List(329));
      cshake1.doOutput(buf, 0, buf.length);
      expect(
          buf,
          equals(createUint8ListFromHexString(
              '309bd7c285fcf8b839c9686b2cc00bd578947bee')));
    });

    test('128 with function name (N)', () {
      var buf = Uint8List(20);
      var cshake1 = CSHAKEDigest(128, Uint8List(29), Uint8List(300));
      cshake1.doOutput(buf, 0, buf.length);
      expect(
          buf,
          equals(createUint8ListFromHexString(
              'ff6aafd83b8d22fc3e2e9b9948b581967ed9c5e7')));
    });
  });
}

void performTest() {
  group('CSHAKE 128', () {
    test('test 1', () {
      var cshake = CSHAKEDigest(
          128, Uint8List(0), Uint8List.fromList('Email Signature'.codeUnits));
      cshake.update(createUint8ListFromHexString('00010203'), 0, 4);
      var res = Uint8List(32);
      cshake.doOutput(res, 0, res.length);

      expect(
          createUint8ListFromHexString(
              'c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5'),
          equals(res));
    });

    test('test 2', () {
      var cshake = CSHAKEDigest(
          128, Uint8List(0), Uint8List.fromList('Email Signature'.codeUnits));
      cshake.update(
          createUint8ListFromHexString('''000102030405060708090A0B0C0D0E0F
              101112131415161718191A1B1C1D1E1F
              202122232425262728292A2B2C2D2E2F
              303132333435363738393A3B3C3D3E3F
              404142434445464748494A4B4C4D4E4F
              505152535455565758595A5B5C5D5E5F
              606162636465666768696A6B6C6D6E6F
              707172737475767778797A7B7C7D7E7F
              808182838485868788898A8B8C8D8E8F
              909192939495969798999A9B9C9D9E9F
              A0A1A2A3A4A5A6A7A8A9AAABACADAEAF
              B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF
              C0C1C2C3C4C5C6C7'''), 0, 1600 ~/ 8);
      var res = Uint8List(32);
      cshake.doOutput(res, 0, res.length);

      expect(
          createUint8ListFromHexString(
              'C5221D50E4F822D96A2E8881A961420F294B7B24FE3D2094BAED2C6524CC166B'),
          equals(res));
    });
  });

  group('CSHAKE 256', () {
    test('test 1', () {
      var cshake = CSHAKEDigest(
          256, Uint8List(0), Uint8List.fromList('Email Signature'.codeUnits));
      cshake.update(createUint8ListFromHexString('00010203'), 0, 4);
      var res = Uint8List(64);
      cshake.doOutput(res, 0, res.length);
      expect(createUint8ListFromHexString('''D008828E2B80AC9D2218FFEE1D070C48
              B8E4C87BFF32C9699D5B6896EEE0EDD1
              64020E2BE0560858D9C00C037E34A969
              37C561A74C412BB4C746469527281C8C'''), equals(res));
    });

    test('test 2', () {
      var cshake = CSHAKEDigest(
          256, Uint8List(0), Uint8List.fromList('Email Signature'.codeUnits));
      cshake.update(
          createUint8ListFromHexString('''000102030405060708090A0B0C0D0E0F
              101112131415161718191A1B1C1D1E1F
              202122232425262728292A2B2C2D2E2F
              303132333435363738393A3B3C3D3E3F
              404142434445464748494A4B4C4D4E4F
              505152535455565758595A5B5C5D5E5F
              606162636465666768696A6B6C6D6E6F
              707172737475767778797A7B7C7D7E7F
              808182838485868788898A8B8C8D8E8F
              909192939495969798999A9B9C9D9E9F
              A0A1A2A3A4A5A6A7A8A9AAABACADAEAF
              B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF
              C0C1C2C3C4C5C6C7'''), 0, 1600 ~/ 8);
      var res = Uint8List(64);
      cshake.doOutput(res, 0, res.length);

      expect(createUint8ListFromHexString('''07DC27B11E51FBAC75BC7B3C1D983E8B
              4B85FB1DEFAF218912AC864302730917
              27F42B17ED1DF63E8EC118F04B23633C
              1DFB1574C8FB55CB45DA8E25AFB092BB'''), equals(res));
    });
  });
}

void testCSHAKESizeEnforcement() {
  group('CSHAKE Tests', () {
    test('enforcement of valid CSHAKE sizes', () {
      CSHAKEDigest(128);
      CSHAKEDigest(256);

      var bitLen = 123;
      try {
        CSHAKEDigest(bitLen);
        fail('Invalid CSHAKE bitlen accepted');
      } on StateError catch (se) {
        expect(se.message,
            'invalid bitLength ($bitLen) for CSHAKE must only be 128 or 256');
      }
    });
  });
}
