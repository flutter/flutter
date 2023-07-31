import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:process_run/src/shell_common.dart';

/// abstract shell context
abstract class ShellContext {
  /// Shell environment
  ShellEnvironment get shellEnvironment;

  /// Which command.
  Future<String?> which(String command,
      {ShellEnvironment? environment, bool includeParentEnvironment = true});

  /// Path context.
  p.Context get path;

  /// Default shell encoding (systemEncoding on iOS)
  Encoding get encoding;

  /// New shell must set itself as a shell Context, shell environement is
  /// no longer relevent.
  Shell newShell(
      {ShellOptions? options,
      @Deprecated('Use options') Map<String, String>? environment,
      @Deprecated('Use options') bool includeParentEnvironment = true});

  ShellEnvironment newShellEnvironment({
    Map<String, String>? environment,
  });
}
