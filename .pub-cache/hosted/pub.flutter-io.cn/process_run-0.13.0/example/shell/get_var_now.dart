import 'common.dart';

Future<void> main() async {
  await shell.run('ds env var get '
      'TEST_USER_VAR_NOW '
      'TEST_LOCAL_VAR_NOW '
      'TEST_VAR_NOW ');
}
