import 'common.dart';

Future<void> main() async {
  await shell.run('''
# Change the env file location to the initial location
ds env var set -u TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH .dart_tool/process_run/env.yaml

''');
}
