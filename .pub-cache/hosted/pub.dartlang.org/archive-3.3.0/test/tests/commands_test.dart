import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:archive/src/tar/tar_command.dart' as tar_command;

import 'test_utils.dart';

void main() {
  test('bin/tar.dart list test2.tar.gz', () {
    // Test that 'tar --list' does not throw.
    tar_command.listFiles(p.join(testDirPath, 'res/test2.tar.gz'));
  });

  test('bin/tar.dart list test2.tar.gz2', () {
    // Test that 'tar --list' does not throw.
    tar_command.listFiles(p.join(testDirPath, 'res/test2.tar.bz2'));
  });

  test('tar extract', () {
    final dir = Directory.systemTemp.createTempSync('foo');

    try {
      //print(dir.path);

      final inputPath = p.join(testDirPath, 'res/test2.tar.gz');

      {
        final tempDir = Directory.systemTemp.createTempSync('dart_archive');
        final tarPath = '${tempDir.path}${Platform.pathSeparator}temp.tar';
        final input = InputFileStream(inputPath);
        final output = OutputFileStream(tarPath);
        GZipDecoder().decodeStream(input, output);

        final aBytes = File(tarPath).readAsBytesSync();
        final bBytes =
            File(p.join(testDirPath, 'res/test2.tar')).readAsBytesSync();

        expect(aBytes.length, equals(bBytes.length));
        var same = true;
        for (var i = 0; same && i < aBytes.length; ++i) {
          same = aBytes[i] == bBytes[i];
        }
        expect(same, equals(true));

        input.close();
        output.close();

        tempDir.deleteSync(recursive: true);
      }

      tar_command.extractFiles(
          p.join(testDirPath, 'res/test2.tar.gz'), dir.path);
      expect(dir.listSync(recursive: true).length, 4);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  /*test('tar create', () {
    final dir = Directory.systemTemp.createTempSync('foo');
    final file = File('${dir.path}${Platform.pathSeparator}foo.txt');
    file.writeAsStringSync('foo bar');

    try {
      // Test that 'tar --create' does not throw.
      tar_command.createTarFile(dir.path);
    } finally {
      dir.delete(recursive: true);
    }
  });*/
}
