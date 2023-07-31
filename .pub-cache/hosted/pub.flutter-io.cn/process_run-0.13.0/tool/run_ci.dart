import 'dart:io';

import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  print(Platform.operatingSystem);
  print(Platform.version);
  await shell.run('''
# Analyze code & format
dart format --set-exit-if-changed bin example lib test tool
dart analyze --fatal-infos --fatal-warnings .
# Run tests
dart test
''');
}
