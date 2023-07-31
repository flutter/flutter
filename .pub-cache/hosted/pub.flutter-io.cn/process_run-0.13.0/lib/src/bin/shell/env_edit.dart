import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/common/import.dart';

import 'env.dart';

class ShellEnvEditCommand extends ShellEnvCommandBase {
  ShellEnvEditCommand()
      : super(name: 'edit', description: 'Edit the environment file');

  @override
  FutureOr<bool> onRun() async {
    if (verbose!) {
      print('envFilePath: $envFilePath');
    }
    await envFileReadOrCreate(write: true);

    Future doRun(String command) async {
      await run(command, commandVerbose: verbose);
    }

    if (Platform.isLinux) {
      if (await which('gedit') != null) {
        await doRun('gedit ${shellArgument(envFilePath!)}');
        return true;
      }
    } else if (Platform.isWindows) {
      if (await which('notepad') != null) {
        await doRun('notepad ${shellArgument(envFilePath!)}');
        return true;
      }
    } else if (Platform.isMacOS) {
      if (await which('open') != null) {
        await doRun('open -a TextEdit ${shellArgument(envFilePath!)}');
        return true;
      }
    }
    if (await which('vi') != null) {
      await doRun('vi ${shellArgument(envFilePath!)}');
      return true;
    }
    print('no editor found');
    return false;
  }
}

/// Direct shell env Edit dump run helper for testing.
Future<void> main(List<String> arguments) async {
  await ShellEnvEditCommand().parseAndRun(arguments);
}
