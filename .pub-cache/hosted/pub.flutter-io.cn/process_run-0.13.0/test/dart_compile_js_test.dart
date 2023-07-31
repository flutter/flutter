@TestOn('vm')
library process_run.dart2js_test;

import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

String getScriptPath(Type type) =>
    (reflectClass(type).owner as LibraryMirror).uri.toFilePath();

class Script {
  static String get path => getScriptPath(Script);
}

String projectTop = dirname(dirname(Script.path));
String testOut = join(projectTop, '.dart_tool', 'process_run_test');

void main() => defineTests();

void defineTests() {
  group('dart compile js', () {
    test('build', () async {
      // from dart2js: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dart2js/.packages' '$SNAPSHOT' '$@'

      var source = join(projectTop, 'test', 'data', 'main.dart');
      var destination = join(testOut, 'dart_compile_js', 'main.js');

      // delete dir if any
      try {
        await Directory(dirname(destination)).delete(recursive: true);
      } catch (_) {}
      try {
        // await Directory(dirname(destination)).create(recursive: true);
      } catch (_) {}

      expect(File(destination).existsSync(), isFalse);
      var shell = Shell(verbose: false);
      final result = (await shell.run(
              'dart compile js -o ${shellArgument(destination)} ${shellArgument(source)}'))
          .first;
      expect(result.exitCode, 0);
      expect(File(destination).existsSync(), isTrue);
    });
  });
}
