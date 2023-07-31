import 'common.dart';

Future<void> main() async {
  await shell.run('''
# Change the env file location
ds env alias set ll ls -l

ds env alias dump

''');
}
