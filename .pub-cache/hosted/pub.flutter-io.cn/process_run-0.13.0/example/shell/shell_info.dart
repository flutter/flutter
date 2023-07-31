import 'common.dart';

Future<void> main() async {
  var now = DateTime.now().toUtc().toIso8601String();
  await shell.run('''
# Make sure to create both env file location
ds env var set TEST_LOCAL_VAR_NOW $now
ds env -u var set TEST_USER_VAR_NOW $now

ds env --info
ds env -u --info

''');
}
