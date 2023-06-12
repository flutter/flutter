import 'package:sqflite_common/src/utils.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite', () {
    test('firstIntValue', () {
      expect(
          firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': 1}
          ]),
          1);
      expect(
          firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': 1},
            <String, Object?>{'test': 1}
          ]),
          1);
      expect(
          firstIntValue(<Map<String, Object?>>[
            <String, Object?>{'test': null}
          ]),
          null);
      expect(
          firstIntValue(<Map<String, Object?>>[<String, Object?>{}]), isNull);
      expect(firstIntValue(<Map<String, Object?>>[]), isNull);
      expect(
          firstIntValue(<Map<String, Object?>>[<String, Object?>{}]), isNull);
    });

    test('hex', () {
      expect(
          hex(<int>[
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            255
          ]),
          '000102030405060708090A0B0C0D0E0F1011FF');
      expect(hex(<int>[]), '');
      expect(hex(<int>[32]), '20');

      try {
        hex(<int>[-1]);
        fail('should fail');
      } on FormatException catch (_) {}

      try {
        hex(<int>[256]);
        fail('should fail');
      } on FormatException catch (_) {}
    });

    test('chunk', () {
      expect(listChunk([], null), isEmpty);
      expect(listChunk([1], null), [
        [1]
      ]);
      expect(listChunk([1], 0), [
        [1]
      ]);
      expect(listChunk([1, 2], 0), [
        [1, 2]
      ]);
      expect(listChunk([1, 2], 2), [
        [1, 2]
      ]);
      expect(listChunk([1, 2], 3), [
        [1, 2]
      ]);
      expect(listChunk([1, 2], 1), [
        [1],
        [2]
      ]);
      expect(listChunk([1, 2, 3], 2), [
        [1, 2],
        [3]
      ]);
    });
  });
}
