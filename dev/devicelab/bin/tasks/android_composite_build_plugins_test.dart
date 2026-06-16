// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Exercises the composite-build ("migrated") plugin model end to end, across a
/// small matrix of Android Gradle Plugin (AGP) versions.
///
/// The committed fixture under dev/integration_tests/composite_flutter_plugin_test contains:
///   * host_app                  - an app depending on all three plugins below.
///   * sample_plugin             - a migrated plugin (consumed as a composite build).
///   * sample_consuming_plugin   - a migrated plugin that depends on sample_plugin
///                                 (validates plugin -> plugin across included builds).
///   * unmigrated_sample_plugin  - a legacy subproject-model plugin
///                                 (validates that migrated and legacy plugins coexist).
///
/// For each AGP version in [_agpVersions] the test builds the host app in debug, profile, and
/// release. Profile is deliberately included: it is the mode most likely to break, because the
/// migrated plugin builds must publish a matching `profile` variant across the composite-build
/// boundary (the app cannot copy its build types into them as it does in the legacy model).
const List<String> _agpVersions = <String>[
  // TODO(gmackall): Tune these to bracket the minimum supported AGP and the AGP version that ships
  //                 native composite-build version unification.
  '8.7.0',
  '9.0.1',
];

const List<String> _buildModes = <String>['debug', 'profile', 'release'];

Future<void> main() async {
  await task(() async {
    section('Find Java');
    final String? javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }
    print('\nUsing JAVA_HOME=$javaHome');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_composite_build_plugins.');
    try {
      // Copy the fixture into a temp dir so we can mutate the host app's AGP version without
      // dirtying the checkout. The whole directory is copied so the relative `path:` dependencies
      // between the host app and the sibling plugins are preserved.
      final source = Directory(
        path.join(
          flutterDirectory.path,
          'dev',
          'integration_tests',
          'composite_flutter_plugin_test',
        ),
      );
      final projectRoot = Directory(path.join(tempDir.path, 'composite_flutter_plugin_test'));
      recursiveCopy(source, projectRoot);

      final hostApp = Directory(path.join(projectRoot.path, 'host_app'));
      final hostAppSettings = File(
        path.join(hostApp.path, 'android', 'settings.gradle.kts'),
      );
      final String originalSettings = hostAppSettings.readAsStringSync();

      for (final String agpVersion in _agpVersions) {
        section('Pin host app to AGP $agpVersion');
        // Rewrite the `com.android.application` plugin version. The Flutter tool reads the host
        // app's resolved AGP version and forwards it to the migrated plugin builds, so pinning the
        // host app is sufficient to drive the whole composite.
        final String pinnedSettings = originalSettings.replaceAllMapped(
          RegExp(r'id\("com\.android\.application"\)\s+version\s+"[^"]*"'),
          (Match _) => 'id("com.android.application") version "$agpVersion"',
        );
        if (pinnedSettings == originalSettings) {
          return TaskResult.failure(
            'Could not find the com.android.application AGP version to pin in '
            '${hostAppSettings.path}.',
          );
        }
        hostAppSettings.writeAsStringSync(pinnedSettings, flush: true);

        section('flutter pub get (AGP $agpVersion)');
        await inDirectory(hostApp, () async {
          await flutter('pub', options: <String>['get']);
        });

        for (final String mode in _buildModes) {
          section('Build host app APK --$mode (AGP $agpVersion)');
          final stderr = StringBuffer();
          await inDirectory(hostApp, () async {
            await evalFlutter(
              'build',
              options: <String>['apk', '--$mode'],
              canFail: true,
              stderr: stderr,
            );
          });

          final String stderrString = stderr.toString();
          // Surface the failure modes specific to composite builds with clear messages.
          if (stderrString.contains('No matching variant') ||
              stderrString.contains('Could not resolve') ||
              stderrString.contains('Unable to find a matching variant')) {
            return TaskResult.failure(
              'Variant resolution failed building --$mode with AGP $agpVersion. This usually means '
              'a migrated plugin did not publish a variant matching the app build type.\n'
              '$stderrString',
            );
          }
          if (stderrString.contains('Using multiple versions of the Android Gradle plugin') ||
              stderrString.contains('requires Android Gradle plugin')) {
            return TaskResult.failure(
              'AGP version unification failed building --$mode with AGP $agpVersion. The host app '
              'AGP version was not propagated to the included plugin builds.\n'
              '$stderrString',
            );
          }

          final apk = File(
            path.join(
              hostApp.path,
              'build',
              'app',
              'outputs',
              'flutter-apk',
              'app-$mode.apk',
            ),
          );
          if (!exists(apk)) {
            return TaskResult.failure(
              'Expected APK ${apk.path} was not produced building --$mode with AGP $agpVersion.\n'
              '$stderrString',
            );
          }
        }

        section('Clean before next AGP version');
        await inDirectory(hostApp, () async {
          await flutter('clean');
        });
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
