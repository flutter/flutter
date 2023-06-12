import 'package:process_run/shell.dart';

Future<void> main() async {
  await buildIos();
}

Future<void> buildIos() async {
  final shell = Shell();
  await shell.run('flutter build ios --no-codesign');
}
