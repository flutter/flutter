import 'package:process_run/src/bin/shell/env_var_delete.dart';
import 'package:process_run/src/bin/shell/env_var_dump.dart';

import 'env_var_get.dart';
import 'env_var_set.dart';
import 'import.dart';

class ShellEnvVarCommand extends ShellBinCommand {
  ShellEnvVarCommand()
      : super(
            name: 'var',
            description: 'Manipulate local and global env variables') {
    addCommand(ShellEnvVarDumpCommand());
    addCommand(ShellEnvVarSetCommand());
    addCommand(ShellEnvVarGetCommand());
    addCommand(ShellEnvVarDeleteCommand());
  }
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarCommand().parseAndRun(arguments);
}
