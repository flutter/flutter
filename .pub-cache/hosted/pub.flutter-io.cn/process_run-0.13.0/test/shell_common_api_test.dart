library process_run.test.shell_common_api_test;

import 'package:process_run/src/mixin/shell_common.dart';
import 'package:test/test.dart';

void main() {
  group('shell_api_test', () {
    test('public', () {
      // ignore: unnecessary_statements
      ShellEnvironment;
      // ignore: unnecessary_statements
      ShellEnvironmentPaths;
      // ignore: unnecessary_statements
      ShellEnvironmentVars;
      // ignore: unnecessary_statements
      ShellEnvironmentAliases;
      // ignore: unnecessary_statements
      Shell;
    });
  });
}
