import 'dart:typed_data';

import 'package:pointycastle/asn1/primitives/asn1_utc_time.dart';
import 'package:test/test.dart';

void main() {
  test('Test named constructor fromBytes', () {
    var bytes = Uint8List.fromList([
      0x17,
      0x0D,
      0x32,
      0x30,
      0x30,
      0x37,
      0x31,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x5A
    ]);

    var valueBytes = Uint8List.fromList([
      0x32,
      0x30,
      0x30,
      0x37,
      0x31,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x5A
    ]);

    var asn1Object = ASN1UtcTime.fromBytes(bytes);
    expect(asn1Object.tag, 23);
    expect(asn1Object.isConstructed, false);
    expect(asn1Object.encodedBytes, bytes);
    expect(asn1Object.valueByteLength, 13);
    expect(asn1Object.valueStartPosition, 2);
    expect(asn1Object.time!.toIso8601String(), '2020-07-10T00:00:00.000Z');
    expect(asn1Object.valueBytes, valueBytes);
  });

  test('Test encode', () {
    var utc = DateTime.utc(2020, 7, 10, 0, 0, 0);

    var asn1Object = ASN1UtcTime(utc);

    var bytes = Uint8List.fromList([
      0x17,
      0x0D,
      0x32,
      0x30,
      0x30,
      0x37,
      0x31,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x5A
    ]);

    expect(asn1Object.encode(), bytes);
  });

  test('Test dump', () {
    var expected = '''UTCTIME 2020-07-10T00:00:00.000Z''';
    var bytes = Uint8List.fromList([
      0x17,
      0x0D,
      0x32,
      0x30,
      0x30,
      0x37,
      0x31,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x30,
      0x5A
    ]);

    var asn1Object = ASN1UtcTime.fromBytes(bytes);
    expect(asn1Object.dump(), expected);
  });
}
