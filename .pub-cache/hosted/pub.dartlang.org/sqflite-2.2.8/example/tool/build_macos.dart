import 'package:process_run/shell.dart';

Future<void> main() async {
  await buildMacos();
}

Future<void> buildMacos() async {
  final shell = Shell();
  await shell.run('flutter build macos');
}
