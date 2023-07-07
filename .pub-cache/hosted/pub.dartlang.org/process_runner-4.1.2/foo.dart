import 'dart:io';

import 'package:process_runner/process_runner.dart';

Future<void> main() async {
  final ProcessRunner processRunner = ProcessRunner();
  final ProcessRunnerResult result = await processRunner.runProcess(<String>['ls'], startMode: ProcessStartMode.detachedWithStdio);

  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');

  // Print interleaved stdout/stderr:
  print('combined: ${result.output}');
}
