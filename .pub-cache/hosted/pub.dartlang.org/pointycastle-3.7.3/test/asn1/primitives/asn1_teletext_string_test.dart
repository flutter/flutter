import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_teletext_string.dart';
import 'package:test/test.dart';

void main() {
  test('Test decode DER', () {
    var bytes = Uint8List.fromList([
      0x14,
      0x37,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x65,
      0x6E,
      0x74,
      0x72,
      0x75,
      0x73,
      0x74,
      0x2E,
      0x6E,
      0x65,
      0x74,
      0x2F,
      0x43,
      0x50,
      0x53,
      0x5F,
      0x32,
      0x30,
      0x34,
      0x38,
      0x20,
      0x69,
      0x6E,
      0x63,
      0x6F,
      0x72,
      0x70,
      0x2E,
      0x20,
      0x62,
      0x79,
      0x20,
      0x72,
      0x65,
      0x66,
      0x2E,
      0x20,
      0x28,
      0x6C,
      0x69,
      0x6D,
      0x69,
      0x74,
      0x73,
      0x20,
      0x6C,
      0x69,
      0x61,
      0x62,
      0x2E,
      0x29
    ]);

    var valueBytes = Uint8List.fromList([
      0x77,
      0x77,
      0x77,
      0x2E,
      0x65,
      0x6E,
      0x74,
      0x72,
      0x75,
      0x73,
      0x74,
      0x2E,
      0x6E,
      0x65,
      0x74,
      0x2F,
      0x43,
      0x50,
      0x53,
      0x5F,
      0x32,
      0x30,
      0x34,
      0x38,
      0x20,
      0x69,
      0x6E,
      0x63,
      0x6F,
      0x72,
      0x70,
      0x2E,
      0x20,
      0x62,
      0x79,
      0x20,
      0x72,
      0x65,
      0x66,
      0x2E,
      0x20,
      0x28,
      0x6C,
      0x69,
      0x6D,
      0x69,
      0x74,
      0x73,
      0x20,
      0x6C,
      0x69,
      0x61,
      0x62,
      0x2E,
      0x29
    ]);

    var asn1Object = ASN1TeletextString.fromBytes(bytes);
    expect(asn1Object.tag, 20);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 55);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.valueBytes, valueBytes);
    expect(asn1Object.stringValue,
        'www.entrust.net/CPS_2048 incorp. by ref. (limits liab.)');
  });

  test('Test decode BER Constructed', () {
    // TODO Create test
  });

  test('Test decode BER Constructed Indefinite Length', () {
    // TODO Create test
  });

  test('Test decode BER Long Form Length', () {
    // TODO Create test
  });
  test('Test encode DER', () {
    var asn1Object = ASN1TeletextString(stringValue: 'US');

    var bytes = Uint8List.fromList([
      0x14,
      0x02,
      0x55,
      0x53,
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test encode BER Constructed', () {
    // TODO Create test
  });

  test('Test encode BER Long Form Length', () {
    // TODO Create test
  });

  test('Test encode BER Constructed Indefinite Length', () {
    // TODO Create test
  });

  test('Test dump', () {
    var expected =
        '''T61STRING www.entrust.net/CPS_2048 incorp. by ref. (limits liab.)''';
    var bytes = Uint8List.fromList([
      0x14,
      0x37,
      0x77,
      0x77,
      0x77,
      0x2E,
      0x65,
      0x6E,
      0x74,
      0x72,
      0x75,
      0x73,
      0x74,
      0x2E,
      0x6E,
      0x65,
      0x74,
      0x2F,
      0x43,
      0x50,
      0x53,
      0x5F,
      0x32,
      0x30,
      0x34,
      0x38,
      0x20,
      0x69,
      0x6E,
      0x63,
      0x6F,
      0x72,
      0x70,
      0x2E,
      0x20,
      0x62,
      0x79,
      0x20,
      0x72,
      0x65,
      0x66,
      0x2E,
      0x20,
      0x28,
      0x6C,
      0x69,
      0x6D,
      0x69,
      0x74,
      0x73,
      0x20,
      0x6C,
      0x69,
      0x61,
      0x62,
      0x2E,
      0x29
    ]);

    var asn1Object = ASN1TeletextString.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
