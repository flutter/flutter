import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

const String _kOrgName = 'com.example.intentsec';
final RegExp _flutterLogRegExp = RegExp(r'flutter:\s+(.+)');

TaskFunction androidIntentSecurityTest({Map<String, String>? environment}) {
  final Directory tempDir = Directory.systemTemp.createTempSync(
    'flutter_devicelab_intent_security.',
  );
  return () async {
    try {
      section('Create app');
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', _kOrgName, 'app'],
          environment: environment,
        );
      });

      final File mainDart = File(path.join(tempDir.absolute.path, 'app', 'lib', 'main.dart'));

      section('Patch lib/main.dart');
      await mainDart.writeAsString(r'''
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void secretAdmin() {
  print('==== VULNERABLE: secretAdmin executed ====');
}

void main() {
  runApp(
    MaterialApp(
      onGenerateRoute: (settings) {
        print('==== ROUTE: ${settings.name} ====');
        return null;
      },
      home: Scaffold(body: Text('Intent Security Test')),
    )
  );
}
''', flush: true);

      final AndroidDevice device = await devices.workingDevice as AndroidDevice;
      await device.unlock();

      section('Build APK');
      await inDirectory(path.join(tempDir.path, 'app'), () async {
        await flutter('build', options: <String>['apk', '--release']);
      });
      
      final String apkPath = path.join(tempDir.path, 'app', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');

      section('Install APK');
      // Uninstall first just in case
      await device.shellExec('pm', <String>['uninstall', '$_kOrgName.app'], silent: true);
      await device.shellExec('pm', <String>['install', '-r', apkPath]);

      Future<void> testEntrypointInjection() async {
        section('Test CWE-926: Entrypoint injection via cold start');
        await device.shellExec('am', <String>['force-stop', '$_kOrgName.app']);
        await device.adb(<String>['logcat', '-c']);
        
        bool entrypointInjected = false;
        final StreamSubscription<String> logcat = device.logcat.listen((String log) {
          if (log.contains('==== VULNERABLE: secretAdmin executed ====')) {
            entrypointInjected = true;
          }
        });

        // Send intent with malicious entrypoint
        await device.shellExec('am', <String>[
          'start',
          '-n',
          '$_kOrgName.app/.MainActivity',
          '--es', 'dart_entrypoint', 'secretAdmin'
        ]);

        await Future<void>.delayed(const Duration(seconds: 5));
        await logcat.cancel();
        
        if (entrypointInjected) {
          throw TaskResult.failure('Entrypoint injection (CWE-926) was successful! The vulnerability is still present.');
        }
      }

      Future<void> testRouteInjection() async {
        section('Test CWE-940: Route injection via cold start');
        await device.shellExec('am', <String>['force-stop', '$_kOrgName.app']);
        await device.adb(<String>['logcat', '-c']);
        
        bool routeInjected = false;
        final StreamSubscription<String> logcat = device.logcat.listen((String log) {
          if (log.contains('==== ROUTE: http://malicious.com/admin/wipe ====')) {
            routeInjected = true;
          }
        });

        // Send intent without ACTION_VIEW to simulate Exploit 2
        await device.shellExec('am', <String>[
          'start',
          '-n',
          '$_kOrgName.app/.MainActivity',
          '-d', 'http://malicious.com/admin/wipe'
        ]);

        await Future<void>.delayed(const Duration(seconds: 5));
        await logcat.cancel();
        
        if (routeInjected) {
          throw TaskResult.failure('Route injection (CWE-940) was successful! The vulnerability is still present.');
        }
      }

      await testEntrypointInjection();
      await testRouteInjection();

      // Ensure app is dead at the end
      await device.shellExec('am', <String>['force-stop', '$_kOrgName.app']);

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}
