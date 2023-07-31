import 'common.dart';

Future<void> main() async {
  await shell.run('''
# Change the env file location
ds env path prepend dummy/relative/path

ds env path dump

''');
}
