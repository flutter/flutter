import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Run tests
dart test -p vm test/shell_test.dart
''');
}
