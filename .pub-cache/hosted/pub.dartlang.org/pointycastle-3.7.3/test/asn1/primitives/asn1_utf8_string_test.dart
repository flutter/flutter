import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:pointycastle/asn1/primitives/asn1_utf8_string.dart';
import 'package:test/test.dart';

void main() {
  test('Test decode DER', () {
    var bytes = Uint8List.fromList([
      0x0C,
      0x0B,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    var valueBytes = Uint8List.fromList(
        [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64]);

    var asn1Object = ASN1UTF8String.fromBytes(bytes);
    expect(asn1Object.tag, 12);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 11);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
    expect(asn1Object.utf8StringValue, 'Hello World');
  });

  test('Test decode BER Constructed', () {
    var bytes = Uint8List.fromList([
      0x2C,
      0x0F,
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    var valueBytes = Uint8List.fromList([
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    var asn1Object = ASN1UTF8String.fromBytes(bytes);
    expect(asn1Object.tag, 44);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 15);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.utf8StringValue, 'Hello World');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Constructed Indefinite Length', () {
    var bytes = Uint8List.fromList([
      0x2C,
      0x80,
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64,
      0x00,
      0x00
    ]);

    var valueBytes = Uint8List.fromList([
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64,
    ]);

    var asn1Object = ASN1UTF8String.fromBytes(bytes);
    expect(asn1Object.tag, 44);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 15);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.elements!.length, 2);
    expect(asn1Object.utf8StringValue, 'Hello World');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test decode BER Long Form Length', () {
    var bytes = Uint8List.fromList([
      0x0C,
      0x81,
      0x0B,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    var valueBytes = Uint8List.fromList(
        [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64]);

    var asn1Object = ASN1UTF8String.fromBytes(bytes);
    expect(asn1Object.tag, 12);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 11);
    expect(asn1Object.valueStartPosition, 3);
    expect(asn1Object.utf8StringValue, 'Hello World');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode DER', () {
    var utf8String = ASN1UTF8String(utf8StringValue: 'Hello World');

    var bytes = Uint8List.fromList([
      0x0C,
      0x0B,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    expect(utf8String.encode(), bytes);
  });

  test('Test encode BER Constructed', () {
    var e1 = ASN1UTF8String(utf8StringValue: 'Hello');

    var e2 = ASN1UTF8String(utf8StringValue: ' World');

    var asn1Object = ASN1UTF8String(
        elements: [e1, e2], tag: ASN1Tags.UTF8_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x2C,
      0x0F,
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_CONSTRUCTED),
        bytes);
  });

  test('Test encode BER Long Form Length', () {
    var asn1Object = ASN1UTF8String(utf8StringValue: 'Hello World');

    var bytes = Uint8List.fromList([
      0x0C,
      0x81,
      0x0B,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    expect(
        asn1Object.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM),
        bytes);
  });

  test('Test encode BER Constructed Indefinite Length', () {
    var e1 = ASN1UTF8String(utf8StringValue: 'Hello');

    var e2 = ASN1UTF8String(utf8StringValue: ' World');

    var asn1Object = ASN1UTF8String(
        elements: [e1, e2], tag: ASN1Tags.UTF8_STRING_CONSTRUCTED);

    var bytes = Uint8List.fromList([
      0x2C,
      0x80,
      0x0C,
      0x05,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x0C,
      0x06,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64,
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
    var expected = '''UTF8STRING Hello World''';
    var bytes = Uint8List.fromList([
      0x0C,
      0x0B,
      0x48,
      0x65,
      0x6C,
      0x6C,
      0x6F,
      0x20,
      0x57,
      0x6F,
      0x72,
      0x6C,
      0x64
    ]);

    var asn1Object = ASN1UTF8String.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
