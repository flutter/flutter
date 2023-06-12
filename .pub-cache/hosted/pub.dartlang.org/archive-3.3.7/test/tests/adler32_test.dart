import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  group('adler32', () {
    test('empty', () {
      final adlerVal = getAdler32([]);
      expect(adlerVal, 1);
    });
    test('1 byte', () {
      final adlerVal = getAdler32([1]);
      expect(adlerVal, 0x20002);
    });
    test('10 bytes', () {
      final adlerVal = getAdler32([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      expect(adlerVal, 0xDC002E);
    });
    test('100000 bytes', () {
      var adlerVal = getAdler32([]);
      for (var i = 0; i < 10000; i++) {
        adlerVal = getAdler32([1, 2, 3, 4, 5, 6, 7, 8, 9, 0], adlerVal);
      }
      expect(adlerVal, 0x96C8DE2B);
    });
  });

  group('adler32 class', () {
    test('empty', () {
      final adler = Adler32();
      expect(adler.close(), [0, 0, 0, 1]);
    });
    test('1 byte', () {
      final adler = Adler32();
      adler.add([1]);
      expect(adler.close(), [0, 0x02, 0, 0x02]);
    });
    test('10 bytes', () {
      final adler = Adler32();
      adler.add([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      expect(adler.close(), [0, 0xDC, 0, 0x2E]);
    });
    test('100000 bytes', () {
      final adler = Adler32();
      for (var i = 0; i < 10000; i++) {
        adler.add([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      }
      expect(adler.close(), [0x96, 0xC8, 0xDE, 0x2B]);
    });
  });
}
