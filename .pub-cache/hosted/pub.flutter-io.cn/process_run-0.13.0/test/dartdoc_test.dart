@TestOn('vm')
library process_run.dartdoc_test;

import 'dart:mirrors';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

String getScriptPath(Type type) =>
    (reflectClass(type).owner as LibraryMirror).uri.toFilePath();

class Script {
  static String get path => getScriptPath(Script);
}

String projectTop = dirname(dirname(Script.path));
String testOut = join(projectTop, '.dart_tool', 'process_run', 'test');

void main() => defineTests();

void defineTests() {
  group('dartdoc', () {
    test('help', () async {
      // ignore: deprecated_member_use_from_same_package
      final result = await runCmd(DartDocCmd(['--help']));
      expect(result.stdout, contains('--version'));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      // ignore: deprecated_member_use_from_same_package
      final result = await runCmd(DartDocCmd(['--version']));
      expect(result.stdout, contains('dartdoc'));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dartdoc: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dartdoc/.packages' '$SNAPSHOT' '$@'

      final result = await runCmd(
          // ignore: deprecated_member_use_from_same_package
          DartDocCmd(['--output', join(testOut, 'dartdoc_build')]));
      //expect(result.stdout, contains('dartdoc'));
      expect(result.exitCode, 0);
      //}, skip: 'failed on SDK 1.19.0'); - fixed in 1.19.1
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: 'Deprecated');
}
