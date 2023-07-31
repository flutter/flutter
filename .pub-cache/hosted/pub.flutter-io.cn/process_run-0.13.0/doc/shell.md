# Shell

Allows to run script from Mac/Windows/Linux in a portable way. Empty lines are added for readibility

```dart
var shell = Shell();

await shell.run('''

# Display some text
echo Hello

# Display dart version
dart --version

# Display pub version
pub --version

''');
```

the command will be looked in the system paths (`PATH` variable). See section later in this this document about
adding system paths.

## Running the script

A script is composed of 1 or multiple lines. Each line becomes a command:
- Each line is trimmed.
- A line starting with `#` will be ignored. `//` and `///` comments are also supported
- A line ending with ` ^` (a space and the `^` character) or ` \\` (a space and one backslash) continue on the next
    line.
- Each command must evaluate to one executable (i.e. no loop, pipe, redirection, bash/powershell specific features).
- Each first word of the line is the executable whose path is resolved using the `which` command. 

If you have spaces in one argument, it must be escaped using double quotes or the `shellArgument` method:

```dart
import 'package:process_run/shell_run.dart';

await run('echo "Hello world"');
await run('echo ${shellArgument('Hello world')}');
```

### Changing directory

You can pushd/popd a directory

```dart
shell = shell.pushd('example');

await shell.run('''

# Listing directory in the example folder
dir

''');
shell = shell.popd();
```


### Handling errors

By default, `run` will throw an error if the `exitCode` is not 0. You can prevent that
with the option `throwOnError` which is true by default:

```dart
void main(List<String> arguments) async {
  // Prevent error to be thrown if exitCode is not 0
  var shell = Shell(throwOnError: false);
  // This won't throw
  await shell.run('dir dummy_folder');

  shell = Shell();
  // This throws an error!
  await shell.run('dir dummy_folder');
}
```

### Adding system path

If somehow you cannot modify the system path, it will look for any path (last) defined in
 `~/.config/tekartik/process_run/env.yaml` on Mac/Linux or `%APPDATA%\tekartik\process_run\env.yaml` on Windows.
 
 See [User configuration file](user_config.md) documentation.
 
### Command line

$ pub global active process_run
$ alias ds='dart pub global run process_run:shell'
 
### Helper

`ShellLinesController` allows listeninging line from a command line script.

```dart
var controller = ShellLinesController();
var shell = Shell(stdout: controller.sink, verbose: false);
controller.stream.listen((event) {
  // Handle output

  // ...
  // If needed kill the shell
  shell.kill();
});
try {
  await shell.run('dart echo.dart some_text');
} on ShellException catch (_) {
  // We might get a shell exception
}
```
### Running sudo (Linux)

You can run your dart program using sudo to run all you child scripts as a super user.

Running a shell script with sudo from inside a dart script ran in non super user mode 
is a little bit trickier as it requires user interaction. One solution (tried on Ubuntu) is to use
`sudo --stdin` to specify reading the password from the stdin.

You can then run script using the following:

```dart
await shell.run('sudo --stdin lsof -i:22');
```

A shared stdin object could be used to redirect dart program input to shell objects.

Here is a more complex example:
```dart
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
```

If you have the password in a variable and not access to stdin (for example in some flutter scenario), you
can do something like:

```dart
import 'dart:io';

import 'package:http/http.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

void main(List<String> arguments) async {
  // Assuming you have the password in `pwd` variable

  // Use sudo --stdin to read the password from stdin
  // Use an alias for simplicity (only need to refer to sudo instead of sudo --stdin
  var env = ShellEnvironment()..aliases['sudo'] = 'sudo --stdin';

  // Create a fake stdin stream from the password variable
  var stdin =
      ByteStream.fromBytes(systemEncoding.encode(pwd)).asBroadcastStream();

  // Execute!
  var shell = Shell(stdin: stdin, environment: env);

  // Should not ask for password
  await shell.run('sudo lsof -i:22');
  await shell.run('sudo lsof -i:80');
}
```

### Running sudo (MacOS)

Turn off Sandboxing by removing it from the Signing & Capabilities tab:

![alt text](https://i.stack.imgur.com/iTRFC.png)

Then run your commands via `osascript` like so:

```
  await shell.run('''
     osascript -e 'do shell script "[YOUR_SHELL_COMMAND_GOES_HERE]" with administrator privileges'
  ''')
```

That will prompt for the user to type his password and then will run the script.
