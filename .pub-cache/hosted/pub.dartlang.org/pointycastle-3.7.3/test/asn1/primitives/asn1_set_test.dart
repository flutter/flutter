import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_set.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    /*
    SEQUENCE (2 elem)
      OBJECT IDENTIFIER 1.2.840.113549.1.1.11 sha256WithRSAEncryption (PKCS #1)
      NULL
    */
    var bytes = Uint8List.fromList([
      0x31,
      0x0D,
      0x06,
      0x09,
      0x2A,
      0x86,
      0x48,
      0x86,
      0xF7,
      0x0D,
      0x01,
      0x01,
      0x0B,
      0x05,
      0x00
    ]);

    var valueBytes = Uint8List.fromList([
      0x06,
      0x09,
      0x2A,
      0x86,
      0x48,
      0x86,
      0xF7,
      0x0D,
      0x01,
      0x01,
      0x0B,
      0x05,
      0x00
    ]);

    var asn1Object = ASN1Set.fromBytes(bytes);
    expect(asn1Object.tag, 49);
    expect(asn1Object.isConstructed, true);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 13);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode', () {
    // Test encoding with zero elements given
    var asn1Object = ASN1Set(elements: []);

    var bytes = Uint8List.fromList([
      0x31,
      0x00,
    ]);

    expect(asn1Object.encode(), bytes);

    // Test encoding with null given
    asn1Object = ASN1Set();

    bytes = Uint8List.fromList([
      0x31,
      0x00,
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''SET (2 elem)
  OBJECT IDENTIFIER 1.2.840.113549.1.1.11 sha256WithRSAEncryption
  NULL''';
    var bytes = Uint8List.fromList([
      0x31,
      0x0D,
      0x06,
      0x09,
      0x2A,
      0x86,
      0x48,
      0x86,
      0xF7,
      0x0D,
      0x01,
      0x01,
      0x0B,
      0x05,
      0x00
    ]);

    var asn1Object = ASN1Set.fromBytes(bytes);
    expect(expected, asn1Object.dump());
  });
}
