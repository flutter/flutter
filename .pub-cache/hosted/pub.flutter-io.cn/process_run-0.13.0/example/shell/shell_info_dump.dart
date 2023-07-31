import 'common.dart';

Future<void> main() async {
  await shell.run('''
ds env var dump
ds env path dump
ds env alias dump

ds env --info
ds env -u --info

''');
}
