import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_generalized_time.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([
      0x18,
      0x0F,
      0x32,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x5A
    ]);

    var valueBytes = Uint8List.fromList([
      0x32,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x5A
    ]);

    var asn1Object = ASN1GeneralizedTime.fromBytes(bytes);
    expect(asn1Object.tag, 24);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 15);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
    expect(asn1Object.dateTimeValue!.toIso8601String(),
        '2010-10-30T10:10:30.000Z');
  });

  test('Test encode', () {
    var utf8String =
        ASN1GeneralizedTime(DateTime.parse('2010-10-30T10:10:30.000Z'));

    var bytes = Uint8List.fromList([
      0x18,
      0x0F,
      0x32,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x5A
    ]);

    expect(utf8String.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''GENERALIZEDTIME 2010-10-30T10:10:30.000Z''';
    var bytes = Uint8List.fromList([
      0x18,
      0x0F,
      0x32,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x31,
      0x30,
      0x31,
      0x30,
      0x33,
      0x30,
      0x5A
    ]);

    var asn1Object = ASN1GeneralizedTime.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
