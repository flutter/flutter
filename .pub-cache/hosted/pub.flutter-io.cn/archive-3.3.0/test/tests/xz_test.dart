import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('xz', () {
    test('decode empty', () {
      var file = File(p.join(testDirPath, 'res/xz/empty.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed);
      expect(data, isEmpty);
    });

    test('decode hello', () {
      // hello.xz has no LZMA compression due to its simplicity.
      var file = File(p.join(testDirPath, 'res/xz/hello.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed);
      expect(data, equals(utf8.encode('hello\n')));
    });

    test('decode crc32', () {
      // Uses a CRC-32 checksum.
      var file = File(p.join(testDirPath, 'res/xz/crc32.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed, verify: true);
      expect(data, equals(utf8.encode('hello\n')));
    });

    test('decode crc64', () {
      // Uses a CRC-64 checksum.
      var file = File(p.join(testDirPath, 'res/xz/crc64.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed, verify: true);
      expect(data, equals(utf8.encode('hello\n')));
    });

    test('decode sha256', () {
      // Uses a SHA-256 checksum.
      var file = File(p.join(testDirPath, 'res/xz/sha256.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed, verify: true);
      expect(data, equals(utf8.encode('hello\n')));
    });

    test('decode nocheck', () {
      // Uses no checksum
      var file = File(p.join(testDirPath, 'res/xz/nocheck.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed, verify: true);
      expect(data, equals(utf8.encode('hello\n')));
    });

    test('decode hello repeated', () {
      // Simple file with a small amount of compression due to repeated data.
      var file = File(p.join(testDirPath, 'res/xz/hello-hello-hello.xz'));
      final compressed = file.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed);
      expect(data, equals(utf8.encode('hello hello hello')));
    });

    test('decode cat.jpg', () {
      var file = File(p.join(testDirPath, 'res/xz/cat.jpg.xz'));
      final compressed = file.readAsBytesSync();

      var b = File(p.join(testDirPath, 'res/cat.jpg'));
      final bBytes = b.readAsBytesSync();

      var data = XZDecoder().decodeBytes(compressed);
      compareBytes(data, bBytes);
    });
  });
}
