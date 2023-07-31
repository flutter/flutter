@TestOn('vm')
library process_run.pub_test;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/which.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('pub', () {
    test('help', () async {
      var result = await runCmd(PubCmd(['--help']));
      expect(result.exitCode, 0);
      // Every other commands write to stdout but dartanalyzer
      expect(result.stdout, contains('Usage: dart pub'));
    });
    test('which', () {
      // To remove once put is removed
      var whichPub = whichSync('pub');
      // might not be in path during the test
      if (whichPub != null) {
        expect(basename(whichPub), getBashOrBatExecutableFilename('pub'));
      }
    });
  });
}
