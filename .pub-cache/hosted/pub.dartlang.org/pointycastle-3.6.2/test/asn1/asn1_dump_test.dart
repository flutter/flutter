import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:test/test.dart';

void main() {
  ///
  /// Helper method
  ///
  List<String> chunk(String s, int chunkSize) {
    var chunked = <String>[];
    for (var i = 0; i < s.length; i += chunkSize) {
      var end = (i + chunkSize < s.length) ? i + chunkSize : s.length;
      chunked.add(s.substring(i, end));
    }
    return chunked;
  }

  var dump1 = '''SEQUENCE (4 elem)
  SEQUENCE (3 elem)
    OBJECT IDENTIFIER 2.5.29.15 keyUsage
    BOOLEAN true
    OCTET STRING (4 byte) 03020186
  SEQUENCE (3 elem)
    OBJECT IDENTIFIER 2.5.29.19 basicConstraints
    BOOLEAN true
    OCTET STRING (5 byte) 30030101FF
  SEQUENCE (2 elem)
    OBJECT IDENTIFIER 2.5.29.14 subjectKeyIdentifier
    OCTET STRING (22 byte) 041403DE503556D14CBB66F0A3E21B1BC397B23DD155
  SEQUENCE (2 elem)
    OBJECT IDENTIFIER 2.5.29.35 authorityKeyIdentifier
    OCTET STRING (24 byte) 3016801403DE503556D14CBB66F0A3E21B1BC397B23DD155''';

  test('Test asn1 dump', () {
    var outer = ASN1Sequence.fromBytes(Uint8List.fromList([
      0x30,
      0x61,
      0x30,
      0x0E,
      0x06,
      0x03,
      0x55,
      0x1D,
      0x0F,
      0x01,
      0x01,
      0xFF,
      0x04,
      0x04,
      0x03,
      0x02,
      0x01,
      0x86,
      0x30,
      0x0F,
      0x06,
      0x03,
      0x55,
      0x1D,
      0x13,
      0x01,
      0x01,
      0xFF,
      0x04,
      0x05,
      0x30,
      0x03,
      0x01,
      0x01,
      0xFF,
      0x30,
      0x1D,
      0x06,
      0x03,
      0x55,
      0x1D,
      0x0E,
      0x04,
      0x16,
      0x04,
      0x14,
      0x03,
      0xDE,
      0x50,
      0x35,
      0x56,
      0xD1,
      0x4C,
      0xBB,
      0x66,
      0xF0,
      0xA3,
      0xE2,
      0x1B,
      0x1B,
      0xC3,
      0x97,
      0xB2,
      0x3D,
      0xD1,
      0x55,
      0x30,
      0x1F,
      0x06,
      0x03,
      0x55,
      0x1D,
      0x23,
      0x04,
      0x18,
      0x30,
      0x16,
      0x80,
      0x14,
      0x03,
      0xDE,
      0x50,
      0x35,
      0x56,
      0xD1,
      0x4C,
      0xBB,
      0x66,
      0xF0,
      0xA3,
      0xE2,
      0x1B,
      0x1B,
      0xC3,
      0x97,
      0xB2,
      0x3D,
      0xD1,
      0x55
    ]));
    var chunks = chunk(base64.encode(outer.encode()), 64);
    var pem = chunks.join('\r\n');

    var lines = LineSplitter.split(pem)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    var base64String = lines.join('');
    var bytes = Uint8List.fromList(base64Decode(base64String));
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject();
    var dump = topLevelSeq.dump();
    expect(dump, dump1);
  });
}
