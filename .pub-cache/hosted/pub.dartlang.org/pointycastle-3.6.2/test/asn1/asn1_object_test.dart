import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/asn1_tags.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([
      0x0C,
      0x0E,
      0x6A,
      0x75,
      0x6E,
      0x6B,
      0x64,
      0x72,
      0x61,
      0x67,
      0x6F,
      0x6E,
      0x73,
      0x2E,
      0x64,
      0x65
    ]);
    var valueBytes = Uint8List.fromList([
      0x6A,
      0x75,
      0x6E,
      0x6B,
      0x64,
      0x72,
      0x61,
      0x67,
      0x6F,
      0x6E,
      0x73,
      0x2E,
      0x64,
      0x65
    ]);
    var asn1Object = ASN1Object.fromBytes(bytes);
    expect(asn1Object.tag, 12);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 14);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode', () {
    var asn1Object = ASN1Object(tag: ASN1Tags.UTF8_STRING);
    asn1Object.valueBytes = Uint8List.fromList([
      0x6A,
      0x75,
      0x6E,
      0x6B,
      0x64,
      0x72,
      0x61,
      0x67,
      0x6F,
      0x6E,
      0x73,
      0x2E,
      0x64,
      0x65
    ]);

    var bytes = Uint8List.fromList([
      0x0C,
      0x0E,
      0x6A,
      0x75,
      0x6E,
      0x6B,
      0x64,
      0x72,
      0x61,
      0x67,
      0x6F,
      0x6E,
      0x73,
      0x2E,
      0x64,
      0x65
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test dump', () {
    var bytes = Uint8List.fromList([
      0xA0,
      0x00,
    ]);

    var asn1Object = ASN1Object.fromBytes(bytes);
    expect('[160] (0 elem)', asn1Object.dump());
  });
}
