import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_var_set_io.dart';

class ShellEnvVarSetCommand extends ShellEnvCommandBase {
  late final helper = ShellEnvVarSetIoHelper(
      shell: Shell(), local: local, verbose: verbose ?? false);

  ShellEnvVarSetCommand()
      : super(
          name: 'set',
          description: 'Set environment variable in a user/local config file',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env var set <name> <command with space>');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var rest = results.rest;
    if (rest.length < 2) {
      stderr.writeln('At least 2 arguments expected');
      exit(1);
    } else {
      var name = rest[0];
      var value = rest.sublist(1).join(' ');
      await helper.setValue(name, value);

      return true;
    }
  }
}

/// Direct shell env Var Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarSetCommand().parseAndRun(arguments);
}
