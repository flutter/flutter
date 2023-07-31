import 'common.dart';

Future<void> main() async {
  var now = DateTime.now().toUtc().toIso8601String();
  await shell.run('''
ds -v env var get TEST_VAR_NOW  
ds -v env var set TEST_VAR_NOW $now
ds -v env var get TEST_VAR_NOW
''');
}
