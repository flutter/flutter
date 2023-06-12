import 'dart:typed_data';

import 'package:hive/src/crypto/crc32.dart';
import 'package:test/test.dart';

void main() {
  group('Crc32', () {
    test('compute', () {
      expect(Crc32.compute(Uint8List(0)), equals(0));
      expect(
        Crc32.compute(Uint8List.fromList('123456789'.codeUnits)),
        0xcbf43926,
      );

      var crc = Crc32.compute(Uint8List.fromList('12345'.codeUnits));
      expect(
        Crc32.compute(Uint8List.fromList('6789'.codeUnits), crc: crc),
        equals(0xcbf43926),
      );
    });
  });
}
