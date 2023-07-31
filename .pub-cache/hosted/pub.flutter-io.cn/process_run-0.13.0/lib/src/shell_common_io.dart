import 'dart:io' as io;

import 'package:process_run/shell.dart' as io;
import 'package:process_run/src/io/env_var_set_io.dart';

import 'shell_common.dart';

class ProcessResultIo implements ProcessResult {
  final io.ProcessResult impl;

  ProcessResultIo(this.impl);

  @override
  int get exitCode => impl.exitCode;

  @override
  int get pid => impl.pid;

  @override
  Object? get stderr => impl.stderr;

  @override
  Object? get stdout => impl.stdout;

  @override
  String toString() => 'exitCode $exitCode, pid $pid';
}

/*
Future<T> _wrapIoException<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on io.ShellException catch (e) {
    throw ShellExceptionIo(e);
  }
}
 */

class ShellIo extends Shell with ShellMixin {
  ShellIo({
    required ShellOptions options,
  }) : super.implWithOptions(options);

  @override
  Future<io.Shell> shellVarOverride(String name, String? value,
      {bool? local}) async {
    var helper = ShellEnvVarSetIoHelper(
        shell: this, local: local ?? true, verbose: options.verbose);
    var env = await helper.setValue(name, value);
    return context.newShell(options: options.clone(shellEnvironment: env));
  }
}

class ShellExceptionIo implements ShellException {
  final io.ShellException impl;

  ShellExceptionIo(this.impl);

  @override
  String get message => impl.message;

  @override
  ProcessResult? get result {
    var implResult = impl.result;
    if (implResult != null) {
      return ProcessResultIo(implResult);
    }
    return null;
  }
}
