import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

Future testSameFileContent(String path1, String path2) async {
  // print(path1);
  expect(await File(path1).readAsString(), await File(path2).readAsString(),
      reason: '$path1 differs');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('macos', () {
    test('ios/macos sample implementation', () async {
      // Somehow we have either...
      // sqflite
      // or
      // sqflite/test
      var dir = Directory.current.path;
      // print(dir);
      if (basename(dir) == 'test') {
        dir = dirname(dir);
      }
      final ios = join(dir, 'ios', 'Classes');
      final macos = join(dir, 'macos', 'Classes');
      for (var file in [
        ...['.h', '.m'].map((ext) => 'SqfliteOperation$ext'),
        ...['.h', '.m'].map((ext) => 'SqflitePlugin$ext')
      ]) {
        await testSameFileContent(join(ios, file), join(macos, file));
      }
    });
  });
}
