import 'package:process_run/shell.dart';

/// Only works on linux, list the process listening on port 22
void main(List<String> arguments) async {
  /// We have use a shared stdin if we want to reuse it.
  var stdin = sharedStdIn;

  /// Use sudo --stdin to read the password from stdin
  /// Use an alias for simplicity (only need to refer to sudo instead of sudo --stdin
  var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';
  var shell = Shell(
      stdin: sharedStdIn,
      // lsof return exitCode 1 if not found
      environment: env,
      throwOnError: false);

  await shell.run('sudo lsof -i:22');
  // second time should not ask for password
  await shell.run('sudo lsof -i:80');

  /// Stop shared stdin
  await stdin.terminate();
}
