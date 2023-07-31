import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/run.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import 'env.dart';
import 'import.dart';

Version shellBinVersion = Version(0, 2, 0);

const flagHelp = 'help';
const flagInfo = 'info';
const flagLocal = 'local';
const flagUser = 'user';
// Force an action
const flagForce = 'force';
const flagDelete = 'delete';
const flagVerbose = 'verbose';
const flagVersion = 'version';

const commandEdit = 'edit-env';
const commandRun = 'run';
const commandEnv = 'env';

const commandEnvEdit = 'edit';
const commandEnvVar = 'var';
const commandEnvVarDump = 'dump';
const commandEnvPath = 'path';
const commandEnvAliases = 'alias';

String get script => 'ds';

class MainShellCommand extends ShellBinCommand {
  MainShellCommand() : super(name: 'ds', version: shellBinVersion) {
    addCommand(ShellEnvCommand());
    addCommand(ShellRunCommand());
  }

  @override
  void printUsage() {
    stdout.writeln('*** ubuntu/windows only for now ***');
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln();
    stdout.writeln('Usage: $script <command> [<arguments>]');
    stdout.writeln('Usage: pub run process_run:shell <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Examples:');
    stdout.writeln();
    stdout.writeln('''
# Set a local env variable
ds env var set MY_VAR my_value
# Get a local env variable
ds env var get USER
# Prepend a path
ds env path prepend ~/.my_path
# Add an alias
ds env alias set hello_world echo Hello World
# Run a command in the overriden envionement
ds run hello_world
ds run echo MY_VAR
# Edit the local environment file
ds env edit
''');
    super.printUsage();
  }

  @override
  void printBaseUsage() {
    stdout.writeln('Process run shell configuration utility');
    stdout.writeln(' -h, --help       Usage help');
    // super.printBaseUsage();
  }

  @override
  FutureOr<bool> onRun() {
    return false;
  }
}

final mainCommand = MainShellCommand();

///
/// write rest arguments as lines
///
Future main(List<String> arguments) async {
  await mainCommand.parseAndRun(arguments);
  await promptTerminate();
}
