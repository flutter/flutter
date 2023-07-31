import 'package:process_run/shell.dart';

import '../echo.dart';

// Shell with hello command and sharedStdIn
var sharedStdinSilentShell =
    Shell(environment: echoEnv, stdin: sharedStdIn, commandVerbose: false);

Future<void> main() async {
  await sharedStdinSilentShell.run('''
# Wait for input
write "shared stdin not used however the program will wait before exiting"
write "unless we call `await sharedStdIn.terminate()`"
''');
  // Uncomment to quit the app
  // await sharedStdIn.terminate();
}
