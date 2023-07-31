## ProcessCmd

### dartbin

Helper to format dart binaries argument that works cross-platforms
* `dart2js`
* `pub`
* `dartanalyzer`
* `dartoc`
* `dartdevc`

### process_cmd

Allow creating `ProcessCmd` object that can be run in different manner

### Sample usage

#### Using ProcessCmd

````dart
import 'dart:io';
import 'package:process_run/cmd_run.dart';

main() async {
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  bool runInShell = Platform.isWindows;

  // Run the command
  ProcessCmd cmd = processCmd('echo', ['hello world'], runInShell: runInShell);
  await runCmd(cmd);

  // Running the command in verbose mode (i.e. display the command and stdout/stderr)
  // > $ echo "hello world"
  // > hello world
  await runCmd(cmd, verbose: true);

  // Stream the out to stdout
  await runCmd(cmd, stdout: stdout);

  // Calling dart
  cmd = DartCmd(['--version']);
  await runCmd(cmd);

  // clone the command to allow other modifications
  cmd = processCmd('echo', ['hello world'], runInShell: runInShell);
  // > $ echo "hello world"
  // > hello world
  await runCmd(cmd, verbose: true);
  // > $ echo "new hello world"
  // > new hello world
  await runCmd(cmd.clone()
    ..arguments = ["new hello world"], verbose: true);

  // Calling dart
  // > $ dart --version
  // > Dart VM version: 1.19.1 (Wed Sep  7 15:59:44 2016) on "linux_x64"
  cmd = DartCmd(['--version']);
  await runCmd(cmd, verbose: true);

  // Calling dart script
  // $ dart example/my_script.dart my_first_arg my_second_arg
  await runCmd(DartCmd(['example/my_script.dart', 'my_first_arg', 'my_second_arg']), commandVerbose: true);

  // Calling pub
  // > $ pub --version
  // > Pub 1.19.1
  await runCmd(PubCmd(['--version']), verbose: true);

  // Listing global activated packages
  // > $ pub global list
  // > ...
  await runCmd(PubCmd(['global', 'list']), verbose: true);
}
````

#### Low level

````dart
import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';

main() async {
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  bool runInShell = Platform.isWindows;

  // Run the command
  await run('echo', ['hello world'], runInShell: runInShell);

  // Stream the out to stdout
  await run('echo', ['hello world'], runInShell: runInShell, stdout: stdout);

  // Calling dart
  await run(dartExecutable, ['--version']);

  // stream the output to stderr
  await run(dartExecutable, ['--version'], stderr: stderr);

  // Listing global activated packages
  await run(dartExecutable, pubArguments(['global', 'list']), verbose: true);
}
````

## Limitations

As noted in the example, windows requires `runInShell` for system commands (echo, type)
but not for regular executables (dart, git...)
