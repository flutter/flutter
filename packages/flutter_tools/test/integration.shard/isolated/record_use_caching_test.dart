// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show platform;
import '../transition_test_utils.dart';
import 'record_use_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(setUpAllRecordUse);
  setUp(setUpRecordUse);
  tearDown(tearDownRecordUse);

  group('record use', () {
    group('caching', () {
      testWithoutContext('build twice caches all targets', () async {
        final String device = hostOs;

        // First build
        await runFlutter(
          <String>['build', device, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$device')],
        );

        // Second build
        final ProcessTestResult result2 = await runFlutter(
          <String>['build', '-v', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('Skipping target: build_hooks'),
            Barrier.contains('Skipping target: link_hooks'),
            Barrier.contains('Built build${Platform.pathSeparator}$device'),
          ],
        );
        if (result2.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result2.exitCode}\n${result2.stderr}\n${result2.stdout}',
          );
        }
      });

      testWithoutContext('changing Dart file reruns link hook but not build hook', () async {
        final String device = hostOs;

        // First build
        await runFlutter(
          <String>['build', device, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$device')],
        );

        // Modify Dart file to change recorded usages
        final File mainDart = appRoot.childDirectory('lib').childFile('main.dart');
        final String content = mainDart.readAsStringSync();
        mainDart.writeAsStringSync(
          content.replaceFirst("translate('friend')", "translate('world')"),
        );

        // Second build
        final ProcessTestResult result2 = await runFlutter(
          <String>['build', '-v', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('Skipping target: build_hooks'),
            Barrier.contains('link_hooks: Starting due to'),
            Barrier.contains('Built build${Platform.pathSeparator}$device'),
          ],
        );
        if (result2.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result2.exitCode}\n${result2.stderr}\n${result2.stdout}',
          );
        }
      });

      testWithoutContext('changing build hook reruns build and link hooks', () async {
        final String device = hostOs;

        // First build
        await runFlutter(
          <String>['build', device, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$device')],
        );

        // Modify build hook output by modifying asset.
        final File dataTranslationsJson = dependencyRoot
            .childDirectory('data')
            .childFile('translations.json');
        final content = jsonDecode(dataTranslationsJson.readAsStringSync()) as Map<String, dynamic>;
        content['No'] = 'Neye!';
        dataTranslationsJson.writeAsStringSync(jsonEncode(content));

        // Second build
        final ProcessTestResult result2 = await runFlutter(
          <String>['build', '-v', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('build_hooks: Starting due to'),
            Barrier.contains('link_hooks: Starting due to'),
            Barrier.contains('Built build${Platform.pathSeparator}$device'),
          ],
        );
        if (result2.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result2.exitCode}\n${result2.stderr}\n${result2.stdout}',
          );
        }
      });

      testWithoutContext('changing build hook (no output change) skips link hook', () async {
        final String device = hostOs;

        // First build
        await runFlutter(
          <String>['build', device, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$device')],
        );

        // Modify build hook in dependency by adding a comment
        final File buildDart = dependencyRoot.childDirectory('hook').childFile('build.dart');
        final String content = buildDart.readAsStringSync();
        buildDart.writeAsStringSync('$content\n// Just a comment\n');

        // Second build
        final ProcessTestResult result2 = await runFlutter(
          <String>['build', '-v', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('build_hooks: Starting due to'),
            Barrier.contains('Skipping target: link_hooks'),
            Barrier.contains('Built build${Platform.pathSeparator}$device'),
          ],
        );
        if (result2.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result2.exitCode}\n${result2.stderr}\n${result2.stdout}',
          );
        }
      });

      testWithoutContext('changing Dart code (no usage change) skips link hook', () async {
        final String device = hostOs;

        // First build
        await runFlutter(
          <String>['build', device, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}$device')],
        );

        // Modify Dart file without changing asset usage (add a print)
        final File mainDart = appRoot.childDirectory('lib').childFile('main.dart');
        final String content = mainDart.readAsStringSync();
        mainDart.writeAsStringSync(
          content.replaceFirst(
            r"print('HELLO: $hello');",
            r"print('HELLO: $hello');"
                '\n'
                r"  print('NO CHANGE');",
          ),
        );

        // Second build
        final ProcessTestResult result2 = await runFlutter(
          <String>['build', '-v', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('Skipping target: build_hooks'),
            Barrier.contains('Skipping target: link_hooks'),
            Barrier.contains('Built build${Platform.pathSeparator}$device'),
          ],
        );
        if (result2.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result2.exitCode}\n${result2.stderr}\n${result2.stdout}',
          );
        }
      });
    });
  });
}
