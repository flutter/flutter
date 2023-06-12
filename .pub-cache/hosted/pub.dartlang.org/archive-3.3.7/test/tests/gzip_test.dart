import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('gzip', () {
    final buffer = List<int>.filled(10000, 0);
    for (var i = 0; i < buffer.length; ++i) {
      buffer[i] = i % 256;
    }

    test('encode/decode', () {
      final compressed = GZipEncoder().encode(buffer);
      final decompressed = GZipDecoder().decodeBytes(compressed!, verify: true);
      expect(decompressed.length, equals(buffer.length));
      for (var i = 0; i < buffer.length; ++i) {
        expect(decompressed[i], equals(buffer[i]));
      }
    });

    test('decode res/cat.jpg.gz', () {
      var b = File(p.join(testDirPath, 'res/cat.jpg'));
      final bBytes = b.readAsBytesSync();

      var file = File(p.join(testDirPath, 'res/cat.jpg.gz'));
      var bytes = file.readAsBytesSync();

      var zBytes = GZipDecoder().decodeBytes(bytes, verify: true);
      compareBytes(zBytes, bBytes);
    });

    test('decode res/test2.tar.gz', () {
      var b = File(p.join(testDirPath, 'res/test2.tar'));
      final bBytes = b.readAsBytesSync();

      var file = File(p.join(testDirPath, 'res/test2.tar.gz'));
      var bytes = file.readAsBytesSync();

      var zBytes = GZipDecoder().decodeBytes(bytes, verify: true);
      compareBytes(zBytes, bBytes);
    });

    test('decode res/a.txt.gz', () {
      final aBytes = aTxt.codeUnits;

      var file = File(p.join(testDirPath, 'res/a.txt.gz'));
      var bytes = file.readAsBytesSync();

      var zBytes = GZipDecoder().decodeBytes(bytes, verify: true);
      compareBytes(zBytes, aBytes);
    });

    test('encode res/cat.jpg', () {
      var b = File(p.join(testDirPath, 'res/cat.jpg'));
      List<int> bBytes = b.readAsBytesSync();

      final compressed = GZipEncoder().encode(bBytes);
      final f = File(p.join(testDirPath, 'out/cat.jpg.gz'));
      f.createSync(recursive: true);
      f.writeAsBytesSync(compressed!);
    });
  });
}
