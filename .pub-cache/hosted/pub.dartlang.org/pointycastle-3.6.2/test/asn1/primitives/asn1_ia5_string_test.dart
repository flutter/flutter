import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/primitives/asn1_ia5_string.dart';
import 'package:test/test.dart';

void main() {
  test('Test decode DER', () {
    var bytes = Uint8List.fromList([
      0x16,
      0x1C,
      0x68,
      0x74,
      0x74,
      0x70,
      0x73,
      0x3A,
      0x2F,
      0x2F,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x2F,
      0x43,
      0x50,
      0x53
    ]);

    var valueBytes = Uint8List.fromList([
      0x68,
      0x74,
      0x74,
      0x70,
      0x73,
      0x3A,
      0x2F,
      0x2F,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x2F,
      0x43,
      0x50,
      0x53
    ]);

    var asn1Object = ASN1IA5String.fromBytes(bytes);
    expect(asn1Object.tag, 22);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 28);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.stringValue, 'https://www.digicert.com/CPS');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Long Form Length', () {
    var bytes = Uint8List.fromList([
      0x16,
      0x81,
      0x0d,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x40,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    var valueBytes = Uint8List.fromList([
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x40,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    var asn1Object = ASN1IA5String.fromBytes(bytes);
    expect(asn1Object.tag, 22);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 13);
    expect(asn1Object.valueStartPosition, 3);
    expect(asn1Object.stringValue, 'test1@rsa.com');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed', () {
    var bytes = Uint8List.fromList([
      0x36,
      0x13,
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    var valueBytes = Uint8List.fromList([
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    var asn1Object = ASN1IA5String.fromBytes(bytes);
    expect(asn1Object.tag, 54);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.elements!.length, 3);
    expect(asn1Object.valueByteLength, 19);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.stringValue, 'test1@rsa.com');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed Indefinite Length', () {
    var bytes = Uint8List.fromList([
      0x36,
      0x80,
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d,
      0x00,
      0x00
    ]);

    var valueBytes = Uint8List.fromList([
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    var asn1Object = ASN1IA5String.fromBytes(bytes);
    expect(asn1Object.tag, 54);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.elements!.length, 3);
    expect(asn1Object.valueByteLength, 19);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.stringValue, 'test1@rsa.com');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode DER', () {
    var asn1Object = ASN1IA5String(stringValue: 'https://www.digicert.com/CPS');

    var bytes = Uint8List.fromList([
      0x16,
      0x1C,
      0x68,
      0x74,
      0x74,
      0x70,
      0x73,
      0x3A,
      0x2F,
      0x2F,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x2F,
      0x43,
      0x50,
      0x53
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test encode BER Constructed', () {
    var e1 = ASN1IA5String(stringValue: 'test1');

    var e2 = ASN1IA5String(stringValue: '@');

    var e3 = ASN1IA5String(stringValue: 'rsa.com');

    var asn1Object = ASN1IA5String(
        elements: [e1, e2, e3], tag: ASN1Tags.IA5_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x36,
      0x13,
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_CONSTRUCTED),
        bytes);
  });

  test('Test encode BER Long Form Length', () {
    var asn1Object = ASN1IA5String(stringValue: 'https://www.digicert.com/CPS');

    var bytes = Uint8List.fromList([
      0x16,
      0x81,
      0x1C,
      0x68,
      0x74,
      0x74,
      0x70,
      0x73,
      0x3A,
      0x2F,
      0x2F,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x2F,
      0x43,
      0x50,
      0x53
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM),
        bytes);
  });

  test('Test encode BER Constructed Indefinite Length', () {
    var e1 = ASN1IA5String(stringValue: 'test1');

    var e2 = ASN1IA5String(stringValue: '@');

    var e3 = ASN1IA5String(stringValue: 'rsa.com');

    var asn1Object = ASN1IA5String(
        elements: [e1, e2, e3], tag: ASN1Tags.IA5_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x36,
      0x80,
      0x16,
      0x05,
      0x74,
      0x65,
      0x73,
      0x74,
      0x31,
      0x16,
      0x01,
      0x40,
      0x16,
      0x07,
      0x72,
      0x73,
      0x61,
      0x2e,
      0x63,
      0x6f,
      0x6d,
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
    var expected = '''IA5String https://www.digicert.com/CPS''';
    var bytes = Uint8List.fromList([
      0x16,
      0x1C,
      0x68,
      0x74,
      0x74,
      0x70,
      0x73,
      0x3A,
      0x2F,
      0x2F,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x64,
      0x69,
      0x67,
      0x69,
      0x63,
      0x65,
      0x72,
      0x74,
      0x2E,
      0x63,
      0x6F,
      0x6D,
      0x2F,
      0x43,
      0x50,
      0x53
    ]);
    var asn1Object = ASN1IA5String.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
