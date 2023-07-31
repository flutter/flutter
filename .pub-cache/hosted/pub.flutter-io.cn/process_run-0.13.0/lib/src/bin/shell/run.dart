import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/user_config.dart';

import 'import.dart';

/// pub run process_run:shell edit-env
class ShellRunCommand extends ShellBinCommand {
  ShellRunCommand()
      : super(
            name: 'run', description: 'Run a command using user environment') {
    parser.addFlag(flagInfo, abbr: 'i', help: 'display info', negatable: false);
  }

  @override
  void printUsage() {
    stdout.writeln('Run a command');
    stdout.writeln();
    stdout.writeln('Usage: $script run <command>');
    stdout.writeln(
        '  command being a command line as a single argument, examples:');
    stdout.writeln("  - 'firebase deploy'");
    stdout.writeln('  - script.bat');
    stdout.writeln('  - script.sh');
    stdout.writeln('');
    stdout.writeln('Get information about the added path(s) and var(s)');
    stdout.writeln('  pub run process_run:shell run --version');

    super.printUsage();
  }

  @override
  FutureOr<bool> onRun() async {
    String? command;
    var commands = results.rest;
    if (commands.isEmpty) {
      stderr.writeln('missing command');
    } else if (commands.length == 1) {
      command = commands.first;
    } else {
      command = shellArguments(commands);
    }

    final displayInfo = results[flagInfo] as bool;
    if (displayInfo) {
      void displayInfo(String title, String path) {
        var config = loadFromPath(path);
        stdout.writeln('# $title');
        stdout.writeln('file: ${relative(path, from: Directory.current.path)}');
        stdout.writeln('vars: ${config.vars}');
        stdout.writeln('paths: ${config.paths}');
      }

      stdout.writeln('command: $command');
      displayInfo('user_env', getUserEnvFilePath()!);
      displayInfo('local_env', getLocalEnvFilePath());

      return true;
    }

    if (command == null) {
      exit(1);
    }
    if (verbose!) {
      print('command: $command');
    }
    await run(command);
    return true;
  }
}

/// Direct shell env Alias dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellRunCommand().parseAndRun(arguments);
}
