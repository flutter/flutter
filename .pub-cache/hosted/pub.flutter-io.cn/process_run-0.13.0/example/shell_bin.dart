import 'package:process_run/shell.dart';

var ds = 'dart run bin/shell.dart';
Future<void> main() async {
  var env = ShellEnvironment();
  // Convenient in development alias to use non global version
  env.aliases['ds'] = 'dart run bin/shell.dart';
  var shell = Shell(environment: env);
  await shell.run('''
# Version
ds --version

# Run using the shell environment (alias, path and var=
ds run echo Hello World

# Set a var
ds env var set MY_VAR my_value

# Set an alias
ds env alias set ll ls -l

# Add a path (prepend only)
ds env path prepend dummy/relative/folder
''');
}
