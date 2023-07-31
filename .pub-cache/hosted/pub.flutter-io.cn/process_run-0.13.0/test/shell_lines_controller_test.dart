@TestOn('vm')
library process_run.test.shell_test;

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/import.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

void main() {
  group('ShellLinesController', () {
    late ShellEnvironment env;
    setUpAll(() {
      env = ShellEnvironment()
        ..aliases['streamer'] = 'dart run ${shellArgument(streamerScriptPath)}';
    });
    test('stream all', () async {
      var ctlr = ShellLinesController();
      var lines = <String>[];
      ctlr.stream.listen((event) {
        lines.add(event);
      });
      var shell = Shell(environment: env, stdout: ctlr.sink, verbose: false);
      await shell.run('streamer --count 10000');
      expect(lines, hasLength(10000));
      ctlr.close();
    });
    test('stream some', () async {
      var ctlr = ShellLinesController();
      var lines = <String>[];
      var shell = Shell(environment: env, stdout: ctlr.sink, verbose: false);
      late StreamSubscription subscription;
      subscription = ctlr.stream.listen((event) {
        lines.add(event);
        if (lines.length >= 10000) {
          shell.kill();
          subscription.cancel();
        }
      });

      // Wait more than 30s
      try {
        await shell.run('streamer --timeout 60000');
      } catch (e) {
        // Should fail
      }
    }, timeout: const Timeout(Duration(milliseconds: 30000)));
  });
}
