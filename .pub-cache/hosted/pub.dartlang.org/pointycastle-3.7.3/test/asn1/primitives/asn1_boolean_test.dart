import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_boolean.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([0x01, 0x01, 0xFF]);

    var valueBytes = Uint8List.fromList([0xFF]);

    var asn1Object = ASN1Boolean.fromBytes(bytes);
    expect(asn1Object.tag, 1);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 1);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode', () {
    var asn1Boolean = ASN1Boolean(true);

    var bytes = Uint8List.fromList([0x01, 0x01, 0xFF]);

    expect(asn1Boolean.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''BOOLEAN true''';
    var bytes = Uint8List.fromList([0x01, 0x01, 0xFF]);

    var asn1Object = ASN1Boolean.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
