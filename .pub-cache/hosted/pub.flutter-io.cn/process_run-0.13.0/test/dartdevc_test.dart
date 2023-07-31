@TestOn('vm')
library process_run.dartdevc_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

void main() => defineTests();

void defineTests() {
  group('dartdevc', () {
    test('help', () async {
      final result = await runCmd(DartDevcCmd(['--help']));
      expect(result.stdout, contains('Usage: dartdevc'));
      expect(result.exitCode, 0);
    });
    test('version', () async {
      final result = await runCmd(DartDevcCmd(['--version']));
      expect(result.stdout, contains('dartdevc'));
      expect(result.exitCode, 0);
    });
    test('build', () async {
      // from dartdevc: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dartdevc/.packages' '$SNAPSHOT' '$@'

      var destination = join(testDir, 'dartdevc_build', 'main.js');

      // delete dir if any
      try {
        await Directory(dirname(destination)).create(recursive: true);
      } catch (_) {}

      final result = await runCmd(
        DartDevcCmd(
            ['-o', destination, join(projectTop, 'test', 'data', 'main.dart')]),
        //verbose: true
      );
      //expect(result.stdout, contains('dartdevc'));
      expect(result.exitCode, 0);
      //}, skip: 'failed on SDK 1.19.0'); - fixed in 1.19.1
    });
  }, skip: true);
}
