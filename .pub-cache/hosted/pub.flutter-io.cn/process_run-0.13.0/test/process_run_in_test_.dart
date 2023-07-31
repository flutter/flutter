@TestOn('vm')
library process_run.process_run_in_test;

import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

void main() {
  test('connect_stdin', () async {
    print("Please enter 'hi'");
    var result = await runExecutableArguments(
        dartExecutable!, [echoScriptPath, '--stdin'],
        stdin: testStdin);
    expect(result.stdout, 'hi');
    print("Please enter 'ho'");
    result = await runExecutableArguments(
        dartExecutable!, [echoScriptPath, '--stdin'],
        stdin: testStdin);
    expect(result.stdout, 'ho');
  });
}
