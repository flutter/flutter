import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_utils.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  test('data offset regression PR #111', () {
    /*
   both vectors are OCTET STRINGS generate using bc-java

     byte[] z = new byte[127];
        for (int t=0; t<z.length; t++) {
            z[t] = (byte)t;
        }
        System.out.println(Hex.toHexString(new DEROctetString(z).getEncoded()));

        z = new byte[128];
        for (int t=0; t<z.length; t++) {
            z[t] = (byte)t;
        }
        System.out.println( Hex.toHexString(new DEROctetString(z).getEncoded()));

   */

    var octetString127Len = createUint8ListFromHexString(
        '047f000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e');
    var octetString128Len = createUint8ListFromHexString(
        '048180000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f');

    var offset127 = ASN1Utils.calculateValueStartPosition(octetString127Len);
    expect(offset127, equals(2));
    expect(octetString127Len[offset127], equals(00));

    var offset128 = ASN1Utils.calculateValueStartPosition(octetString128Len);
    expect(offset128, equals(3));
    expect(octetString128Len[offset128], equals(00));
  });

  test('Test decodeLength', () {
    // Test with second byte larger than 127
    expect(ASN1Utils.decodeLength(Uint8List.fromList([0x30, 0x82, 0x01, 0x26])),
        294);
    // Test with second byte larger than 127 but missing byte at the end
    try {
      ASN1Utils.decodeLength(Uint8List.fromList([0x0, 0x82, 0x01]));
      fail('Expected RangeError due to missing byte');
    } catch (e) {
      expect(e, e as RangeError);
    }
    // Test with second byte less than 127
    expect(ASN1Utils.decodeLength(Uint8List.fromList([0x02, 0x01, 0x00])), 1);
    expect(
        ASN1Utils.decodeLength(Uint8List.fromList([
          0x0C,
          0x0B,
          0x45,
          0x6E,
          0x74,
          0x77,
          0x69,
          0x63,
          0x6B,
          0x6C,
          0x75,
          0x6E,
          0x67
        ])),
        11);
    expect(
        ASN1Utils.decodeLength(Uint8List.fromList([
          0x04,
          0x14,
          0x03,
          0xDE,
          0x50,
          0x35,
          0x56,
          0xD1,
          0x4C,
          0xBB,
          0x66,
          0xF0,
          0xA3,
          0xE2,
          0x1B,
          0x1B,
          0xC3,
          0x97,
          0xB2,
          0x3D,
          0xD1,
          0x55
        ])),
        20);
  });

  test('Test encodeLength', () {
    // Test with length larger than 127
    expect(ASN1Utils.encodeLength(294), Uint8List.fromList([0x82, 0x01, 0x26]));
    // Test with length less than 127
    expect(ASN1Utils.encodeLength(1), Uint8List.fromList([0x01]));
    expect(ASN1Utils.encodeLength(11), Uint8List.fromList([0x0B]));
    // Test with length less than 127 and longform true
    expect(ASN1Utils.encodeLength(13), Uint8List.fromList([0x0d]));
    expect(ASN1Utils.encodeLength(13, longform: true),
        Uint8List.fromList([0x81, 0x0d]));
  });

  test('Test calculateValueStartPosition', () {
    // Test with length larger than 127
    expect(
        ASN1Utils.calculateValueStartPosition(
            Uint8List.fromList([0x30, 0x82, 0x01, 0x26])),
        4);
    // Test with length less than 127
    expect(
        ASN1Utils.calculateValueStartPosition(
            Uint8List.fromList([0x02, 0x01, 0x00])),
        2);
    // Test with only one byte
    try {
      ASN1Utils.calculateValueStartPosition(Uint8List.fromList([0x0]));
      fail('Expected RangeError due to missing byte');
    } catch (e) {
      expect(e, e as RangeError);
    }
  });

  test('Test isConstructed', () {
    // IA5 String
    expect(ASN1Utils.isConstructed(0x36), true);
    expect(ASN1Utils.isConstructed(0x16), false);

    // Bit String
    expect(ASN1Utils.isConstructed(0x23), true);
    expect(ASN1Utils.isConstructed(0x03), false);

    // Octet String
    expect(ASN1Utils.isConstructed(0x24), true);
    expect(ASN1Utils.isConstructed(0x04), false);

    // Printable String
    expect(ASN1Utils.isConstructed(0x33), true);
    expect(ASN1Utils.isConstructed(0x13), false);

    // T61 String
    expect(ASN1Utils.isConstructed(0x34), true);
    expect(ASN1Utils.isConstructed(0x14), false);

    // Sequence
    expect(ASN1Utils.isConstructed(0x30), true);
  });
}
