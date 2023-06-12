import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_enumerated.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([0x0a, 0x01, 0x02]);

    var valueBytes = Uint8List.fromList([0x02]);

    var asn1Object = ASN1Enumerated.fromBytes(bytes);
    expect(asn1Object.tag, 10);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 1);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
    expect(asn1Object.integer.toString(), '2');
  });

  test('Test encode', () {
    var utf8String = ASN1Enumerated(2);

    var bytes = Uint8List.fromList([0x0a, 0x01, 0x02]);

    expect(utf8String.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''INTEGER 2''';
    var bytes = Uint8List.fromList([0x0a, 0x01, 0x02]);

    var asn1Object = ASN1Enumerated.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
