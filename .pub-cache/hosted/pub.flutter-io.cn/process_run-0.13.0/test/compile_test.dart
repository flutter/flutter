@TestOn('vm')
library process_run_test_windows_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

void main() {
  test('compile and run exe', () async {
    var folder =
        Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
    var exeExtension = Platform.isWindows ? '.exe' : '';
    var echoExePath = join('build', folder, 'process_run_echo$exeExtension');
    var echoExeDir = dirname(echoExePath);
    var echoExeName = basename(echoExePath);
    var shell = Shell(verbose: false);
    if (!File(echoExePath).existsSync()) {
      Directory(echoExeDir).createSync(recursive: true);
      await shell.run(
          'dart compile exe ${shellArgument(join('example', 'echo.dart'))} -o ${shellArgument(echoExePath)}');
    }
    // Try relative access
    var exePathShell = Shell(workingDirectory: echoExeDir, verbose: false);
    var lines = (await exePathShell
            .run('${shellArgument(join('.', echoExeName))} --stdout test'))
        .outLines;
    expect(lines, ['test']);

    // Without using a relative path, this should fail
    try {
      await exePathShell.run('${shellArgument(echoExeName)} --stdout test');
      fail('should fail');
    } on ShellException catch (_) {
      // print(e);
    }

    expect(lines, ['test']);
  },
      skip: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
      timeout: const Timeout(Duration(minutes: 10)));
}
