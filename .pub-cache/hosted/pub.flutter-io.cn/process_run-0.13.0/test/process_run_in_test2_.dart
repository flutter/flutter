@TestOn('vm')
library process_run.process_run_in_test2_;

import 'dart:async';

import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

Future main() async {
  print("Please enter 'hi'");
  var result = await runExecutableArguments(
    dartExecutable!, [echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  print('out: ${result.stdout}');
  print("Please enter 'ho'");
  result = await runExecutableArguments(
    dartExecutable!, [echoScriptPath, '--stdin'],
    //stdin: testStdin);
  );
  print('out: ${result.stdout}');

  // unfortunately using testStdin hangs...
}
