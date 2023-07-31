import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/io/env_io.dart';
import 'package:process_run/src/shell_common.dart';

class ShellEnvVarSetIoHelper extends ShellEnvIoHelper {
  /// Local should be true by default
  ShellEnvVarSetIoHelper(
      {required super.shell, required super.local, super.verbose = true});

  Future<ShellEnvironment> setValue(String name, String? value) async {
    if (verbose) {
      stdout.writeln('file $label: $envFilePath');
      stdout.writeln('before: ${jsonEncode(ShellEnvironment().vars)}');
    }

    var fileContent = await envFileReadOrCreate();
    bool modified;
    if (value != null) {
      modified = fileContent.addVar(name, value);
    } else {
      modified = fileContent.deleteVar(name);
    }
    if (modified) {
      if (verbose) {
        stdout.writeln('writing file');
      }
      await fileContent.write();
    }
    if (local && name == localEnvFilePathEnvKey) {
      stderr.writeln('$name cannot be set in local file');
    }
    // reload
    var newShellEnvironment = shell.context.newShellEnvironment(
        environment: ShellEnvironment(environment: shell.options.environment));
    if (value == null) {
      newShellEnvironment.vars.remove(name);
    } else {
      newShellEnvironment.vars[name] = value;
    }
    if (verbose) {
      stdout.writeln('After: ${jsonEncode(ShellEnvironment().vars)}');
    }
    return newShellEnvironment;
  }
}
