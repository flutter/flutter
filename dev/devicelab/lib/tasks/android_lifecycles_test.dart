// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

const String _kOrgName = 'com.example.activitydestroy';

final RegExp _lifecycleSentinelRegExp = RegExp(r'==== lifecycle\: (.+) ====');

/// Tests the following Android lifecycles: Activity#onStop(), Activity#onResume(), Activity#onPause()
/// from Dart perspective in debug, profile, and release modes.
TaskFunction androidLifecyclesTest({
  Map<String, String>? environment,
}) {
  final Directory tempDir = Directory.systemTemp
      .createTempSync('flutter_devicelab_activity_destroy.');
  return () async {
    try {
      section('Create app');
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--platforms',
            'android',
            '--org',
            _kOrgName,
            'app',
          ],
          environment: environment,
        );
      });

      final File mainDart = File(path.join(
        tempDir.absolute.path,
        'app',
        'lib',
        'main.dart',
      ));
      if (!mainDart.existsSync()) {
        return TaskResult.failure('${mainDart.path} does not exist');
      }

      section('Patch lib/main.dart');
      await mainDart.writeAsString(r'''
 import 'package:flutter/widgets.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('==== lifecycle: $state ====');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(LifecycleObserver());
  runApp(Container());
}
''', flush: true);

      final List<String> androidLifecycles = <String>[];

      Future<TaskResult> runTestFor(String mode) async {
        section('Flutter run (mode: $mode)');

        late Process run;
        await inDirectory(path.join(tempDir.path, 'app'), () async {
          run = await startProcess(
            path.join(flutterDirectory.path, 'bin', 'flutter'),
            flutterCommandArgs('run', <String>['--$mode']),
          );
        });

        final AndroidDevice device = await devices.workingDevice as AndroidDevice;
        await device.unlock();

        final StreamController<String> lifecyles = StreamController<String>();

        final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String log) {
            final RegExpMatch? match = _lifecycleSentinelRegExp.firstMatch(log);
              print('stdout: $log');
              if (match == null) {
                return;
              }
              final String lifecycle = match[1]!;
              androidLifecycles.add(lifecycle);

              print('stdout: Found app lifecycle: $lifecycle');
              lifecyles.add(lifecycle);
          });

        final StreamSubscription<void> stderr = run.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String log) {
            print('stderr: $log');
          });

        final StreamIterator<String> lifecycleItr = StreamIterator<String>(lifecyles.stream);

        {
          const String expected = 'AppLifecycleState.resumed';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        section('Toggling app switch (mode: $mode)');
        await device.shellExec('input', <String>['keyevent', 'KEYCODE_APP_SWITCH']);

        {
          const String expected = 'AppLifecycleState.inactive';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        section('Bring activity to foreground (mode: $mode)');
        await device.shellExec('am', <String>['start', '--activity-single-top', '$_kOrgName.app/.MainActivity']);

        {
          const String expected = 'AppLifecycleState.resumed';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        section('Launch Settings app (mode: $mode)');
        await device.shellExec('am', <String>['start', '-a', 'android.settings.SETTINGS']);

        {
          const String expected = 'AppLifecycleState.inactive';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        {
          const String expected = 'AppLifecycleState.paused';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        section('Bring activity to foreground (mode: $mode)');
        await device.shellExec('am', <String>['start', '--activity-single-top', '$_kOrgName.app/.MainActivity']);

        {
          const String expected = 'AppLifecycleState.resumed';
          await lifecycleItr.moveNext();
          final String got = lifecycleItr.current;
          if (expected != got) {
            return TaskResult.failure('expected lifecycles: `$expected`, but got` $got`');
          }
        }

        run.kill();

        section('Stop subscriptions (mode: $mode)');

        await lifecycleItr.cancel();
        await lifecyles.close();
        await stdout.cancel();
        await stderr.cancel();
        return TaskResult.success(null);
      }

      final TaskResult debugResult = await runTestFor('debug');
      if (debugResult.failed) {
        return debugResult;
      }

      final TaskResult profileResult = await runTestFor('profile');
      if (profileResult.failed) {
        return profileResult;
      }

      final TaskResult releaseResult = await runTestFor('release');
       if (releaseResult.failed) {
        return releaseResult;
      }

      return TaskResult.success(null);
    } finally {
      rmTree(tempDir);
    }
  };
}
