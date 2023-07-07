import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:test/test.dart';

void main() {
  test('Test decode DER', () {
    var bytes = Uint8List.fromList([0x04, 0x04, 0x03, 0x02, 0x05, 0xA0]);

    var valueBytes = Uint8List.fromList([0x03, 0x02, 0x05, 0xA0]);

    var asn1Object = ASN1OctetString.fromBytes(bytes);
    expect(asn1Object.tag, 4);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 4);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.octets, valueBytes);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Long Form Length', () {
    var bytes = Uint8List.fromList(
        [0x04, 0x81, 0x08, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]);

    var valueBytes =
        Uint8List.fromList([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]);

    var asn1Object = ASN1OctetString.fromBytes(bytes);
    expect(asn1Object.tag, 4);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 8);
    expect(asn1Object.valueStartPosition, 3);
    expect(asn1Object.octets, valueBytes);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed', () {
    var bytes = Uint8List.fromList([
      0x24,
      0x0c,
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef
    ]);

    var valueBytes = Uint8List.fromList([
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef
    ]);

    var octets =
        Uint8List.fromList([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]);

    var asn1Object = ASN1OctetString.fromBytes(bytes);
    expect(asn1Object.tag, 36);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 12);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.octets, octets);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed Indefinite Length', () {
    var bytes = Uint8List.fromList([
      0x24,
      0x80,
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef,
      0x00,
      0x00
    ]);

    var valueBytes = Uint8List.fromList([
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef
    ]);

    var octets =
        Uint8List.fromList([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]);

    var asn1Object = ASN1OctetString.fromBytes(bytes);
    expect(asn1Object.tag, 36);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 12);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.octets, octets);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode DER', () {
    var asn1Object =
        ASN1OctetString(octets: Uint8List.fromList([0x03, 0x02, 0x05, 0xA0]));

    var bytes = Uint8List.fromList([0x04, 0x04, 0x03, 0x02, 0x05, 0xA0]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test encode BER Long Form Length', () {
    var asn1Object = ASN1OctetString(
        octets: Uint8List.fromList(
            [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]));

    var bytes = Uint8List.fromList(
        [0x04, 0x81, 0x08, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM),
        bytes);
  });

  test('Test encode BER Constructed', () {
    var e1 = ASN1OctetString(
        octets: Uint8List.fromList([
      0x01,
      0x23,
      0x45,
      0x67,
    ]));

    var e2 =
        ASN1OctetString(octets: Uint8List.fromList([0x89, 0xab, 0xcd, 0xef]));

    var asn1Object = ASN1OctetString(
        elements: [e1, e2], tag: ASN1Tags.OCTET_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x24,
      0x0c,
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_CONSTRUCTED),
        bytes);
  });

  test('Test encode BER Constructed Indefinite Length', () {
    var e1 = ASN1OctetString(
        octets: Uint8List.fromList([
      0x01,
      0x23,
      0x45,
      0x67,
    ]));

    var e2 =
        ASN1OctetString(octets: Uint8List.fromList([0x89, 0xab, 0xcd, 0xef]));

    var asn1Object = ASN1OctetString(
        elements: [e1, e2], tag: ASN1Tags.OCTET_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x24,
      0x80,
      0x04,
      0x04,
      0x01,
      0x23,
      0x45,
      0x67,
      0x04,
      0x04,
      0x89,
      0xab,
      0xcd,
      0xef,
      0x00,
      0x00
    ]);

    expect(
        asn1Object.encode(
            encodingRule:
                ASN1EncodingRule.ENCODING_BER_CONSTRUCTED_INDEFINITE_LENGTH),
        bytes);
  });

  test('Test dump', () {
    var expected =
        '''OCTET STRING (20 byte) 03DE503556D14CBB66F0A3E21B1BC397B23DD155''';
    var bytes = Uint8List.fromList([
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
    ]);
    var asn1Object = ASN1OctetString.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
