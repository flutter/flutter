import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';

void main() {
  group('archive', () {
    test('replace existing file', () {
      final archive = Archive();
      archive.addFile(ArchiveFile("a", 1, Uint8List.fromList([0])));
      archive.addFile(ArchiveFile("b", 1, Uint8List.fromList([1])));
      archive.addFile(ArchiveFile("c", 1, Uint8List.fromList([2])));

      archive.addFile(ArchiveFile("b", 1, Uint8List.fromList([3])));

      archive.addFile(ArchiveFile("陳大文_1_test.png", 1, [4]));

      expect(archive.length, 4);
      expect(archive[0].name, "a");
      expect(archive[1].name, "b");
      expect(archive[2].name, "c");
      expect(archive[3].name, "陳大文_1_test.png");

      expect(archive[0].content[0], 0);
      expect(archive[1].content[0], 3);
      expect(archive[2].content[0], 2);
      expect(archive[3].content[0], 4);
    });

    test('clear', () {
      final archive = Archive();
      archive.addFile(ArchiveFile("a", 1, Uint8List.fromList([0])));
      archive.addFile(ArchiveFile("b", 1, Uint8List.fromList([1])));
      archive.addFile(ArchiveFile("c", 1, Uint8List.fromList([2])));
      archive.clear();
      expect(archive.length, 0);
    });
  });
}
