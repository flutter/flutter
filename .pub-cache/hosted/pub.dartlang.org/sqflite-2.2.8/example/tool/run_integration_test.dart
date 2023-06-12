import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main(List<String> arguments) async {
  var deviceId = ShellEnvironment().vars['SQFLITE_TEST_DEVICE_ID'];
  if (deviceId == null) {
    // ignore: avoid_print
    stdout.writeln(
        'To run on a specific device set SQFLITE_TEST_DEVICE_ID=<deviceId>,'
        ' for example \'emulator-5554\' typically for android emulator');
  }
  await runIntegrationTest(deviceId: deviceId);
}

Future<void> runIntegrationTest({String? deviceId}) async {
  final shell = Shell();

  await shell.run('flutter drive${deviceId != null ? ' -d $deviceId ' : ''}'
      ' --driver=test_driver/integration_test.dart'
      ' --target=integration_test/sqflite_test.dart');
}
