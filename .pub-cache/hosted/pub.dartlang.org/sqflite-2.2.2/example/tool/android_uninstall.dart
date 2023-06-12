import 'package:process_run/shell.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

adb uninstall com.tekartik.sqfliteexample

''');
}
