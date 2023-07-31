@TestOn('vm')
library process_run.dartdoc_test;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

String testOut = join('.dart_tool', 'process_run', 'test');

void main() => defineTests();

void defineTests() {
  group('dart_doc', () {
    test('build', () async {
      // from dartdoc: exec '$DART' --packages='$BIN_DIR/snapshots/resources/dartdoc/.packages' '$SNAPSHOT' '$@'

      try {
        // Try output-dir first
        final result = await runExecutableArguments('dart',
            ['doc', '--output-dir', join(testOut, 'dartdoc_build'), '.'],
            verbose: true);
        //expect(result.stdout, contains('dartdoc'));
        expect(result.exitCode, 0);
      } catch (e) {
        // New for dev?
        print('failed with --output-dir: $e');
        // Try output-dir first
        final result = await runExecutableArguments(
            'dart', ['doc', '--output', join(testOut, 'dartdoc_build'), '.'],
            verbose: true);
        //expect(result.stdout, contains('dartdoc'));
        expect(result.exitCode, 0);
      }
      //}, skip: 'failed on SDK 1.19.0'); - fixed in 1.19.1
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
