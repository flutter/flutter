import 'dart:async';
import 'dart:io';

import 'package:process_run/cmd_run.dart';

@Deprecated('Deb only, verbose')
Future<ProcessResult> devRunCmd(ProcessCmd cmd,
    {bool? verbose,
    bool? commandVerbose,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr}) async {
  return runCmd(cmd,
      verbose: true,
      commandVerbose: commandVerbose,
      stdin: stdin,
      stderr: stderr);
}
