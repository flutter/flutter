import 'dart:async';
import 'dart:io';

import 'package:process_run/process_run.dart';

Future main() async {
  // Run the command
  await runExecutableArguments('echo', ['hello world']);

  // Stream the out to stdout
  await runExecutableArguments('echo', ['hello world']);

  // Calling dart
  await runExecutableArguments('dart', ['--version'], verbose: true);

  // stream the output to stderr
  await runExecutableArguments('dart', ['--version'], stderr: stderr);
}
