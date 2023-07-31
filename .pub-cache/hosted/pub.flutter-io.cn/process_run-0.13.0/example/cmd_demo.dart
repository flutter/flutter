import 'dart:async';
import 'dart:io';
import 'package:process_run/cmd_run.dart';

Future main() async {
  // Simple echo command
  // Somehow windows requires runInShell for the system commands
  final runInShell = Platform.isWindows;

  // Run the command
  var cmd = ProcessCmd('echo', ['hello world'], runInShell: runInShell);
  await runCmd(cmd);

  // Running the command in verbose mode (i.e. display the command and stdout/stderr)
  // > $ echo 'hello world'
  // > hello world
  await runCmd(cmd, verbose: true);

  // Stream the out to stdout
  await runCmd(cmd, stdout: stdout);

  // Calling dart
  cmd = DartCmd(['--version']);
  await runCmd(cmd);

  // clone the command to allow other modifications
  cmd = ProcessCmd('echo', ['hello world'], runInShell: runInShell);
  // > $ echo 'hello world'
  // > hello world
  await runCmd(cmd, verbose: true);
  // > $ echo 'new hello world'
  // > new hello world
  await runCmd(cmd.clone()..arguments = ['new hello world'], verbose: true);

  // Calling dart
  // > $ dart --version
  // > Dart VM version: 1.19.1 (Wed Sep  7 15:59:44 2016) on 'linux_x64'
  cmd = DartCmd(['--version']);
  await runCmd(cmd, verbose: true);

  // Calling dart script
  // $ dart example/my_script.dart my_first_arg my_second_arg
  await runCmd(
      DartCmd(['example/my_script.dart', 'my_first_arg', 'my_second_arg']),
      commandVerbose: true);

  // Calling pub
  // > $ pub --version
  // > Pub 1.19.1
  await runCmd(PubCmd(['--version']), verbose: true);

  // Listing global activated packages
  // > $ pub global list
  // > ...
  await runCmd(PubCmd(['global', 'list']), verbose: true);
}
