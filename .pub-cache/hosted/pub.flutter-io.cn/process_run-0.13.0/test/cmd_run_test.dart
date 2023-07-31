@TestOn('vm')
library process_run.cmd_run_test;

import 'dart:io';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/src/common/import.dart';
import 'package:test/test.dart';

import 'dartbin_test.dart';
import 'process_run_test_common.dart';

void main() {
  group('cmd_run', () {
    test('DartCmd', () async {
      final result = await runCmd(DartCmd(['--version']));
      testDartVersionOutput(result);
      // Dart VM version: 2.0.0-dev.65.0 (Tue Jun 26 14:17:21 2018 +0200) on 'linux_x64'
    });

    test('connect_stdin', () async {
      ProcessCmd cmd = DartCmd([echoScriptPath, '--stdin']);
      final streamController = StreamController<List<int>>();

      final future = runCmd(cmd, stdin: streamController.stream);

      streamController.add('in'.codeUnits);
      await streamController.close();
      final result = await future;
      expect(result.stderr, '');
      expect(result.stdout, 'in');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);
    }); // to investigate

    test('connect_stdout', () async {
      ProcessCmd cmd = DartCmd([echoScriptPath, '--stdout', 'out']);
      var result = await runCmd(cmd);
      expect(result.stderr, '');
      expect(result.stdout, 'out');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);

      final out = TestSink<List<int>>();
      result = await runCmd(cmd, verbose: true, stdout: out);
      expect(out.results.length, 2, reason: '${out.results}');
      expect(systemEncoding.decode(out.results[0].asValue!.value),
          '\$ dart $echoScriptPath --stdout out\n');
      expect(systemEncoding.decode(out.results[1].asValue!.value), 'out');
    });

    test('connect_stderr', () async {
      ProcessCmd cmd = DartCmd([echoScriptPath, '--stderr', 'err']);
      var result = await runCmd(cmd);
      expect(result.stderr, 'err');
      expect(result.stdout, '');
      expect(result.pid, isNotNull);
      expect(result.exitCode, 0);

      final err = TestSink<List<int>>();
      result = await runCmd(cmd, stderr: err);
      expect(err.results.length, 1);
      expect(systemEncoding.decode(err.results[0].asValue!.value), 'err');
    });
  });
}
