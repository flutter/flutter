@TestOn('vm')
library process_run.cmd_run_exception_test;

import 'dart:io';

import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

void main() {
  group('runCmdException', () {
    test('wrong directory', () async {
      // Should get something like
      // $ /usr/lib/dart/bin/dart version
      // ProcessException: No such file or directory
      // Command: /usr/lib/dart/bin/dart version
      // $ /usr/lib/dart/bin/dart version
      // workingDirectory: /dummy
      try {
        await runCmd(DartCmd(['version'])..workingDirectory = '/dummy');
        fail('should fail');
      } catch (e) {
        expect(e, const TypeMatcher<ProcessException>());
      }
    });
  });
}
