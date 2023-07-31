import 'package:process_run/src/bin/shell/env_path_dump.dart';
import 'package:process_run/src/bin/shell/env_path_prepend.dart';

import 'env_path_delete.dart';
import 'env_path_get.dart';
import 'import.dart';

class ShellEnvPathCommand extends ShellBinCommand {
  ShellEnvPathCommand() : super(name: 'path', description: 'Path operations') {
    addCommand(ShellEnvPathDumpCommand());
    addCommand(ShellEnvPathPrependCommand());
    addCommand(ShellEnvPathDeleteCommand());
    addCommand(ShellEnvPathGetCommand());
  }
}

/// Direct shell env Path dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathCommand().parseAndRun(arguments);
}
