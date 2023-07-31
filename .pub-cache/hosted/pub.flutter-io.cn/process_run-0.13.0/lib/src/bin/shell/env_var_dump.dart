import 'package:process_run/shell.dart';

import 'import.dart';

class ShellEnvVarDumpCommand extends ShellBinCommand {
  ShellEnvVarDumpCommand()
      : super(name: 'dump', description: 'Dump environment variable');

  @override
  FutureOr<bool> onRun() async {
    var vars = ShellEnvironment().vars;
    var keys = vars.keys.toList()
      ..sort((t1, t2) => t1.toLowerCase().compareTo(t2.toLowerCase()));
    for (var key in keys) {
      var value = vars[key];
      stdout.writeln('$key: $value');
    }
    return true;
  }
}

/// Direct shell env var dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvVarDumpCommand().parseAndRun(arguments);
}
