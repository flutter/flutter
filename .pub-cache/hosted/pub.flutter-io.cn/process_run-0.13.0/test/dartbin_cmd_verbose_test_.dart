@TestOn('vm')
library process_run.dartbin_cmd_verbose_test;

import 'package:process_run/cmd_run.dart' show runCmd;
import 'package:process_run/shell.dart';
import 'package:process_run/src/dartbin_cmd.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('dartbin_cmd_verbose', () {
    test('all', () async {
      expect(
          (await runCmd(
                  DartFmtCmd(// ignore: deprecated_member_use_from_same_package
                      ['--help']),
                  verbose: true))
              .exitCode,
          0);

      // To remove once dart stable hits 2.17.0
      if (dartVersion < Version(2, 17, 0, pre: '0')) {
        expect(
            // ignore: deprecated_member_use_from_same_package
            (await runCmd(Dart2JsCmd(['--help']), verbose: true)).exitCode,
            0);
        expect(
            // ignore: deprecated_member_use_from_same_package
            (await runCmd(DartDocCmd(['--help']), verbose: true)).exitCode,
            0);
      }

      expect((await runCmd(PubCmd(['--help']), verbose: true)).exitCode, 0);
    });
  });
}
