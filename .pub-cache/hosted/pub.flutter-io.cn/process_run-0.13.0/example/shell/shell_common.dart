import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell();
  var result = await shell.run('echo Hello');
  print(result);
  print(await which('ls'));
}
