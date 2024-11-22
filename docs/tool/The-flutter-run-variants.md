# The `flutter run` variants

We aspire to reach a state where `flutter run` has the following modes:

- `flutter run`: builds a debug version of the app and starts it in "hot reload" mode, then shows the console UI to manipulate the running instance.
- `flutter run --no-hot`: builds a debug version of the app and starts it directly, then shows the console UI to manipulate the running instance.
- `flutter run --profile`: builds a profile version of the app and starts it directly, then shows the console UI to manipulate the running instance.
- `flutter run --release`: builds a release version of the app and starts it directly, then shows the console UI to manipulate the running instance.

Adding `--machine` in any of the situations above spawns a [flutter daemon](https://github.com/flutter/flutter/blob/main/packages/flutter_tools/doc/daemon.md#flutter-run---machine) which:
* changes the output to JSON so that it can be more easily consumed by IDEs, and
* allows the use of JSON commands to interact with the running application (e.g. stopping the application).

All of the commands above launch a Flutter application and do not return until that Flutter application exits. Adding `--no-resident` in any of the situations causes the command to return immediately after the application has been launched rather than waiting until the application exits.
