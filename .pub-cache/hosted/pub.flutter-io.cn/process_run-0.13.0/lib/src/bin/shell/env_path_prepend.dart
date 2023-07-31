import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';

class ShellEnvPathPrependCommand extends ShellEnvCommandBase {
  ShellEnvPathPrependCommand()
      : super(
          name: 'prepend',
          description: 'Prepend path for executable lookup',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env path prepend <path1> <path2>...');
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
        stdout.writeln('before: ${jsonEncode(ShellEnvironment().paths)}');
      }
      var fileContent = await envFileReadOrCreate();
      if (fileContent.prependPaths(paths)) {
        await fileContent.write();
      }
      // Force reload
      shellEnvironment = null;
      if (verbose!) {
        stdout.writeln('After: ${jsonEncode(ShellEnvironment().paths)}');
      }
      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathPrependCommand().parseAndRun(arguments);
}
