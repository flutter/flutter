import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/dump.dart';

import 'import.dart';

class ShellEnvPathDumpCommand extends ShellBinCommand {
  ShellEnvPathDumpCommand()
      : super(name: 'dump', description: 'Dump process_run paths');

  @override
  FutureOr<bool> onRun() async {
    dumpStringList(ShellEnvironment().paths);
    return true;
  }
}

/// Direct shell env Path dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvPathDumpCommand().parseAndRun(arguments);
}
