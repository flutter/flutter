import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/primitives/asn1_printable_string.dart';
import 'package:test/test.dart';

void main() {
  test('Test decode DER', () {
    var bytes = Uint8List.fromList([
      0x13,
      0x02,
      0x55,
      0x53,
    ]);

    var valueBytes = Uint8List.fromList([
      0x55,
      0x53,
    ]);

    var asn1Object = ASN1PrintableString.fromBytes(bytes);
    expect(asn1Object.tag, 19);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 2);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.stringValue, 'US');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed', () {
    var bytes = Uint8List.fromList([
      0x33,
      0x0f,
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    var valueBytes = Uint8List.fromList([
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    var asn1Object = ASN1PrintableString.fromBytes(bytes);
    expect(asn1Object.tag, 51);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 15);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.stringValue, 'Test User 1');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed Indefinite Length', () {
    var bytes = Uint8List.fromList([
      0x33,
      0x80,
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31,
      0x00,
      0x00
    ]);

    var valueBytes = Uint8List.fromList([
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    var asn1Object = ASN1PrintableString.fromBytes(bytes);
    expect(asn1Object.tag, 51);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 15);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.stringValue, 'Test User 1');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Long Form Length', () {
    var bytes = Uint8List.fromList([
      0x13,
      0x81,
      0x0b,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    var valueBytes = Uint8List.fromList(
        [0x54, 0x65, 0x73, 0x74, 0x20, 0x55, 0x73, 0x65, 0x72, 0x20, 0x31]);

    var asn1Object = ASN1PrintableString.fromBytes(bytes);
    expect(asn1Object.tag, 19);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 11);
    expect(asn1Object.valueStartPosition, 3);
    expect(asn1Object.stringValue, 'Test User 1');
    expect(asn1Object.valueBytes, valueBytes);
  });
  test('Test encode DER', () {
    var asn1Object = ASN1PrintableString(stringValue: 'US');

    var bytes = Uint8List.fromList([
      0x13,
      0x02,
      0x55,
      0x53,
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test encode BER Constructed', () {
    var e1 = ASN1PrintableString(stringValue: 'Test ');

    var e2 = ASN1PrintableString(stringValue: 'User 1');

    var asn1Object = ASN1PrintableString(
        elements: [e1, e2], tag: ASN1Tags.PRINTABLE_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x33,
      0x0f,
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_CONSTRUCTED),
        bytes);
  });

  test('Test encode BER Long Form Length', () {
    var asn1Object = ASN1PrintableString(stringValue: 'Test User 1');

    var bytes = Uint8List.fromList([
      0x13,
      0x81,
      0x0b,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM),
        bytes);
  });

  test('Test encode BER Constructed Indefinite Length', () {
    var e1 = ASN1PrintableString(stringValue: 'Test ');

    var e2 = ASN1PrintableString(stringValue: 'User 1');

    var asn1Object = ASN1PrintableString(
        elements: [e1, e2], tag: ASN1Tags.PRINTABLE_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x33,
      0x80,
      0x13,
      0x05,
      0x54,
      0x65,
      0x73,
      0x74,
      0x20,
      0x13,
      0x06,
      0x55,
      0x73,
      0x65,
      0x72,
      0x20,
      0x31,
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
    var expected = '''PRINTABLE STRING US''';
    var bytes = Uint8List.fromList([
      0x13,
      0x02,
      0x55,
      0x53,
    ]);

    var asn1Object = ASN1PrintableString.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
