import 'dart:io' as io;

import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as path;

String adbPath() {
  final String? androidHome = io.Platform.environment['ANDROID_HOME'] ?? io.Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null) {
    return 'adb';
  } else {
    return path.join(androidHome, 'platform-tools', 'adb');
  }
}

Future<void> main() async {
  // Say the magic words..
  io.Process run = await io.Process.start(adbPath(), const <String>[
    'shell',
    'settings',
    'put',
    'secure',
    'enabled_accessibility_services',
    'com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService',
  ]);
  await run.exitCode;
  print('run.exitCode ${run.exitCode}');

  await integrationDriver();

  // ... And turn it off again
  run = await io.Process.start(adbPath(), const <String>[
    'shell',
    'settings',
    'put',
    'secure',
    'enabled_accessibility_services',
    'null',
  ]);
  await run.exitCode;
}
