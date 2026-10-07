import 'dart:io' as io;

import 'package:flutter_devicelab/tasks/web_benchmarks.dart';

Future<void> main(List<String> args) async {
  final int exitCode = await runBenchmarkCli(args);
  io.exit(exitCode);
}
