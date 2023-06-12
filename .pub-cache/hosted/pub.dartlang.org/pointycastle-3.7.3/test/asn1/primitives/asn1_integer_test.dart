import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([
      0x02,
      0x10,
      0x0F,
      0xED,
      0xEB,
      0x0D,
      0x80,
      0x08,
      0x13,
      0x40,
      0xC6,
      0x44,
      0xE4,
      0xB7,
      0xA6,
      0x80,
      0x8F,
      0x4E
    ]);

    var valueBytes = Uint8List.fromList([
      0x0F,
      0xED,
      0xEB,
      0x0D,
      0x80,
      0x08,
      0x13,
      0x40,
      0xC6,
      0x44,
      0xE4,
      0xB7,
      0xA6,
      0x80,
      0x8F,
      0x4E
    ]);

    var asn1Object = ASN1Integer.fromBytes(bytes);
    expect(asn1Object.tag, 2);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 16);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
    expect(asn1Object.integer.toString(),
        '21173761728093306653035526320543534926');
  });

  test('Test encode', () {
    var utf8String =
        ASN1Integer(BigInt.parse('21173761728093306653035526320543534926'));

    var bytes = Uint8List.fromList([
      0x02,
      0x10,
      0x0F,
      0xED,
      0xEB,
      0x0D,
      0x80,
      0x08,
      0x13,
      0x40,
      0xC6,
      0x44,
      0xE4,
      0xB7,
      0xA6,
      0x80,
      0x8F,
      0x4E
    ]);

    expect(utf8String.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''INTEGER 21173761728093306653035526320543534926''';
    var bytes = Uint8List.fromList([
      0x02,
      0x10,
      0x0F,
      0xED,
      0xEB,
      0x0D,
      0x80,
      0x08,
      0x13,
      0x40,
      0xC6,
      0x44,
      0xE4,
      0xB7,
      0xA6,
      0x80,
      0x8F,
      0x4E
    ]);

    var asn1Object = ASN1Integer.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
