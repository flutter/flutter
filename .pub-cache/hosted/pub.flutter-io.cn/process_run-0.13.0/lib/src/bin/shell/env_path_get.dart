import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/dump.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';

class ShellEnvPathGetCommand extends ShellEnvCommandBase {
  ShellEnvPathGetCommand()
      : super(
          name: 'get',
          description: 'Get the paths from environment',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env path get <path1> <path2>...');
    stdout.writeln();
    stdout.writeln('Output for the path present:');
    stdout.writeln('<path1>');
    stdout.writeln('<path3>');
    stdout.writeln('...');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var paths = results.rest;
    if (paths.isEmpty) {
      stderr.writeln('At least 1 path argument expected');
      exit(1);
    } else {
      if (verbose!) {
        stdout.writeln('File $label: $envFilePath');
      }
      dumpStringList(ShellEnvironment()
          .paths
          .where((element) => paths.contains(element))
          .toList());

      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathGetCommand().parseAndRun(arguments);
}
