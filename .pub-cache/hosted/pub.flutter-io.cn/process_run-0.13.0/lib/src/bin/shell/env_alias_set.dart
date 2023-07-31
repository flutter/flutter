import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env.dart';
import 'package:process_run/src/common/import.dart';

class ShellEnvAliasSetCommand extends ShellEnvCommandBase {
  ShellEnvAliasSetCommand()
      : super(
          name: 'set',
          description: 'Set process_run alias',
        );

  @override
  void printUsage() {
    stdout.writeln('ds env alias set <name> <command with space>');
    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    var rest = results.rest;
    if (rest.length < 2) {
      stderr.writeln('At least 2 arguments expected');
      exit(1);
    } else {
      if (verbose!) {
        stdout.writeln('file $label: $envFilePath');
        stdout.writeln('before: ${jsonEncode(ShellEnvironment().aliases)}');
      }
      var alias = rest[0];
      var command = rest.sublist(1).join(' ');
      var fileContent = await envFileReadOrCreate();
      if (fileContent.addAlias(alias, command)) {
        await fileContent.write();
      }
      // Force reload
      shellEnvironment = null;
      if (verbose!) {
        stdout.writeln('After: ${jsonEncode(ShellEnvironment().aliases)}');
      }
      return true;
    }
  }
}

/// Direct shell env Alias Set run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvAliasSetCommand().parseAndRun(arguments);
}
