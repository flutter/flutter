import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart' as ds;
import 'package:process_run/src/shell_common.dart';
import 'package:process_run/src/shell_common_io.dart';
import 'package:process_run/src/shell_context_common.dart';
import 'package:process_run/src/shell_environment.dart' as io;

class ShellContextIo implements ShellContext {
  @override
  ShellEnvironment get shellEnvironment =>
      io.ShellEnvironment(environment: ds.shellEnvironment);

  @override
  p.Context get path => p.context;

  @override
  Future<String?> which(String command,
          {ShellEnvironment? environment,
          bool includeParentEnvironment = true}) =>
      ds.which(command,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment);

  @override
  Encoding get encoding => systemEncoding;

  @override
  ShellEnvironment newShellEnvironment({Map<String, String>? environment}) {
    return io.ShellEnvironment(environment: environment);
  }

  @override
  Shell newShell(
      {ShellOptions? options,
      Map<String, String>? environment,
      bool includeParentEnvironment = true}) {
    var ioShell = ShellIo(options: options ?? ShellOptions());
    ioShell.context = this;
    return ioShell;
  }
}
