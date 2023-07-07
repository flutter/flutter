import 'dart:typed_data';

import 'package:pointycastle/asn1/asn1_encoding_rule.dart';
import 'package:pointycastle/asn1/primitives/asn1_null.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([0x05, 0x00]);

    var valueBytes = Uint8List.fromList([]);

    var asn1Object = ASN1Null.fromBytes(bytes);
    expect(asn1Object.tag, 5);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 0);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);

    bytes = Uint8List.fromList([0x05, 0x81, 0x00]);
    asn1Object = ASN1Null.fromBytes(bytes);

    expect(asn1Object.tag, 5);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 0);
    expect(asn1Object.valueStartPosition, 3);
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode DER', () {
    var asn1Null = ASN1Null();

    var bytes = Uint8List.fromList([0x05, 0x00]);

    expect(asn1Null.encode(), bytes);

    var asn1Object = ASN1Null.fromBytes(Uint8List.fromList([0x05, 0x81, 0x00]));

    expect(asn1Object.encode(), bytes);
  });

  test('Test encode BER Long Form Length', () {
    var asn1Null = ASN1Null();

    var bytes = Uint8List.fromList([0x05, 0x81, 0x00]);

    expect(
        asn1Null.encode(
            encodingRule: ASN1EncodingRule.ENCODING_BER_LONG_LENGTH_FORM),
        bytes);
  });

  test('Test dump', () {
    var expected = '''NULL''';
    var bytes = Uint8List.fromList([0x05, 0x00]);

    var asn1Object = ASN1Null.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
