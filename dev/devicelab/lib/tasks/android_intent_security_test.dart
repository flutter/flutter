// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction androidIntentSecurityTest({Map<String, String>? environment}) {
  return () async {
    final tests = <TaskFunction>[
      _testReleaseNonPrebuiltEntrypointInjection(environment: environment),
      _testReleaseNonPrebuiltRouteInjection(environment: environment),
    ];

    for (final test in tests) {
      final TaskResult result = await test();
      if (result.failed) {
        return result;
      }
    }

    return TaskResult.success(null);
  };
}

/// Tests entrypoint injection in release mode on a non-prebuilt app.
TaskFunction _testReleaseNonPrebuiltEntrypointInjection({Map<String, String>? environment}) {
  const org = 'com.example.intentsec';
  final Directory tempDir = Directory.systemTemp.createTempSync(
    'flutter_devicelab_intent_security_entrypoint.',
  );
  return () async {
    try {
      section('Create app for entrypoint test');
      await _createApp(tempDir, org, environment);

      final mainDart = File(path.join(tempDir.absolute.path, 'app', 'lib', 'main.dart'));
      const maliciousEntrypointName = 'secretAdmin';
      const vulnerableLog = '==== VULNERABLE: secretAdmin executed ====';

      section('Patch lib/main.dart for entrypoint test');
      await mainDart.writeAsString('''
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void $maliciousEntrypointName() {
  print('$vulnerableLog');
}

void main() {
  print('==== SAFE: main executed ====');
  runApp(
    MaterialApp(
      home: Scaffold(body: Text('Intent Security Test')),
    )
  );
}
''', flush: true);

      final device = await devices.workingDevice as AndroidDevice;
      await device.unlock();

      section('Build APK for entrypoint test');
      await _buildApk(tempDir, 'release');

      final String apkPath = path.join(tempDir.path, 'app', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
      await _installApk(device, org, apkPath);

      section('Test entrypoint injection via cold start');
      await device.shellExec('am', <String>['force-stop', '$org.app']);
      await device.adb(<String>['logcat', '-c']);

      final appStarted = Completer<void>();
      var entrypointInjected = false;
      final StreamSubscription<String> logcat = device.logcat.listen((String log) {
        if (log.contains(vulnerableLog)) {
          entrypointInjected = true;
          if (!appStarted.isCompleted) {
            appStarted.complete();
          }
        } else if (log.contains('==== SAFE: main executed ====')) {
          if (!appStarted.isCompleted) {
            appStarted.complete();
          }
        }
      });

      // Send Intent with malicious entrypoint
      await device.shellExec('am', <String>[
        'start',
        '-n',
        '$org.app/.MainActivity',
        '--es',
        'dart_entrypoint',
        maliciousEntrypointName,
      ]);

      try {
        await appStarted.future.timeout(const Duration(seconds: 30));
      } catch (_) {
        return TaskResult.failure('App did not start within 30 seconds.');
      } finally {
        await logcat.cancel();
      }

      // Ensure app is dead at the end.
      await device.shellExec('am', <String>['force-stop', '$org.app']);

      if (entrypointInjected) {
        return TaskResult.failure(
          'Entrypoint injection was successful! The vulnerability is still present.',
        );
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

/// Tests route injection in release mode on a non-prebuilt app.
TaskFunction _testReleaseNonPrebuiltRouteInjection({Map<String, String>? environment}) {
  const org = 'com.example.intentsec';
  final Directory tempDir = Directory.systemTemp.createTempSync(
    'flutter_devicelab_intent_security_route.',
  );
  return () async {
    try {
      section('Create app for route test');
      await _createApp(tempDir, org, environment);

      final mainDart = File(path.join(tempDir.absolute.path, 'app', 'lib', 'main.dart'));

      section('Patch lib/main.dart for route test');
      await mainDart.writeAsString(r'''
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      onGenerateRoute: (settings) {
        print('==== ROUTE: ${settings.name} ====');
        return MaterialPageRoute(
          builder: (context) => Scaffold(body: Text('Intent Security Test'))
        );
      },
    )
  );
}
''', flush: true);

      final device = await devices.workingDevice as AndroidDevice;
      await device.unlock();

      section('Build APK for route test');
      await _buildApk(tempDir, 'release');

      final String apkPath = path.join(
        tempDir.path,
        'app',
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      );
      await _installApk(device, org, apkPath);

      section('Test route injection via cold start');
      const maliciousRoute = 'http://malicious.com/admin/wipe';

      // 1. Test sending an ACTION_VIEW intent that is malicious (not self-sent and doesn't match intent-filters)
      section('Test 1: Malicious ACTION_VIEW intent');
      await device.shellExec('am', <String>['force-stop', '$org.app']);
      await device.adb(<String>['logcat', '-c']);

      final routeCompleter1 = Completer<void>();
      var routeInjectedActionView = false;
      final StreamSubscription<String> logcat1 = device.logcat.listen((String log) {
        if (log.contains('==== ROUTE: $maliciousRoute ====')) {
          routeInjectedActionView = true;
          if (!routeCompleter1.isCompleted) {
            routeCompleter1.complete();
          }
        } else if (log.contains('==== ROUTE: / ====')) {
          if (!routeCompleter1.isCompleted) {
            routeCompleter1.complete();
          }
        }
      });

      await device.shellExec('am', <String>[
        'start',
        '-a',
        'android.intent.action.VIEW',
        '-n',
        '$org.app/.MainActivity',
        '-d',
        maliciousRoute,
      ]);

      try {
        await routeCompleter1.future.timeout(const Duration(seconds: 30));
      } catch (_) {
        return TaskResult.failure('App did not start or route within 30 seconds.');
      } finally {
        await logcat1.cancel();
      }

      if (routeInjectedActionView) {
        return TaskResult.failure(
          'Route injection via malicious ACTION_VIEW intent was successful! The vulnerability is still present.',
        );
      }

      // 2. Test sending a non-ACTION_VIEW intent with data (which should be rejected because it is not ACTION_VIEW and not self-sent)
      section('Test 2: Malicious non-ACTION_VIEW intent');
      await device.shellExec('am', <String>['force-stop', '$org.app']);
      await device.adb(<String>['logcat', '-c']);

      final routeCompleter2 = Completer<void>();
      var routeInjectedNonActionView = false;
      final StreamSubscription<String> logcat2 = device.logcat.listen((String log) {
        if (log.contains('==== ROUTE: $maliciousRoute ====')) {
          routeInjectedNonActionView = true;
          if (!routeCompleter2.isCompleted) {
            routeCompleter2.complete();
          }
        } else if (log.contains('==== ROUTE: / ====')) {
          if (!routeCompleter2.isCompleted) {
            routeCompleter2.complete();
          }
        }
      });

      await device.shellExec('am', <String>[
        'start',
        '-a',
        'android.intent.action.MAIN',
        '-n',
        '$org.app/.MainActivity',
        '-d',
        maliciousRoute,
      ]);

      try {
        await routeCompleter2.future.timeout(const Duration(seconds: 30));
      } catch (_) {
        return TaskResult.failure('App did not start or route within 30 seconds.');
      } finally {
        await logcat2.cancel();
      }

      // Ensure app is dead at the end
      await device.shellExec('am', <String>['force-stop', '$org.app']);

      if (routeInjectedNonActionView) {
        return TaskResult.failure(
          'Route injection via malicious non-ACTION_VIEW intent was successful! The vulnerability is still present.',
        );
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

Future<void> _createApp(Directory tempDir, String org, Map<String, String>? environment) async {
  await inDirectory(tempDir, () async {
    await flutter(
      'create',
      options: <String>['--platforms', 'android', '--org', org, 'app'],
      environment: environment,
    );
  });
}

Future<void> _buildApk(Directory tempDir, String buildMode) async {
  await inDirectory(path.join(tempDir.path, 'app'), () async {
    await flutter('build', options: <String>['apk', '--$buildMode']);
  });
}

Future<void> _installApk(AndroidDevice device, String org, String apkPath) async {
  section('Install APK');
  // Uninstall first just in case. This is allowed to fail if the app isn't already installed.
  await device.adb(<String>['shell', 'pm', 'uninstall', '$org.app'], silent: true, canFail: true);
  await device.adb(<String>['install', '-r', apkPath]);
}
