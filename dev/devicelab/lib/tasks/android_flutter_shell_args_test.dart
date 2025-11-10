// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction androidFlutterShellArgsTest({Map<String, String>? environment}) {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');

    try {
      section('Create module project');

      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', 'androidFlutterShellArgsTest'],
        );
      });

      section('Insert AOT shared library name metadata into manifest');
      final List<(String, String)> metadataKeyPairs = <(String, String)>[
        (
          'io.flutter.embedding.android.AOTSharedLibraryName',
          'something/completely/and/totally/invalid.so',
        ),
      ];
      _addMetadataToManifest(tempDir.path, metadataKeyPairs);

      section('Run Flutter Android app in debug mode with modified manifest');
      Completer<bool> foundInvalidAotLibraryLog = Completer<bool>();
      late Process run;
      await inDirectory(path.join(tempDir.path, 'app'), () async {
        run = await startFlutter('run', options: <String>['--debug', '--verbose']);
      });
      // "Skipping unsafe AOT shared library name flag: "
      //         + aotSharedLibraryPath
      //         + ". Please ensure that the library is vetted and placed in your application's internal storage."
      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            if (line.contains('Skipping unsafe AOT shared library name flag:')) {
              foundInvalidAotLibraryLog.complete(true);
            }
          });

      section('Check that warning log for invalid AOT shared library name is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundInvalidAotLibraryLog.future,
        run.exitCode,
      ]);

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };

  //   section('Build APK');
  //   await flutter(
  //     'build',
  //     options: <String>['apk', '--config-only'],
  //     environment: environment,
  //     workingDirectory: '${flutterDirectory.path}/dev/integration_tests/android_views',
  //   );

  //   /// Any gradle command downloads gradle if not already present in the cache.
  //   /// ./gradlew dependencies downloads any gradle defined dependencies to the cache.
  //   /// https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html
  //   /// Downloading gradle and downloading dependencies are a common source of flakes
  //   /// and moving those to an infra step that can be retried shifts the blame
  //   /// individual tests to the infra itself.
  //   section('Download android dependencies');
  //   final int exitCode = await exec(
  //     './gradlew',
  //     <String>['-q', 'dependencies'],
  //     workingDirectory: '${flutterDirectory.path}/dev/integration_tests/android_views/android',
  //   );
  //   if (exitCode != 0) {
  //     return TaskResult.failure('Failed to download gradle dependencies');
  //   }
  //   section('Run flutter drive on android views');
  //   await flutter(
  //     'drive',
  //     options: <String>[
  //       '--browser-name=android-chrome',
  //       '--android-emulator',
  //       '--no-start-paused',
  //       '--purge-persistent-cache',
  //       '--device-timeout=30',
  //     ],
  //     environment: environment,
  //     workingDirectory: '${flutterDirectory.path}/dev/integration_tests/android_views',
  //   );
  //   return TaskResult.success(null);
  // };
}

// TODO(camsim99): De-dupe from perf_tests.dart
void _addMetadataToManifest(String testDirectory, List<(String, String)> keyPairs) {
  final String manifestPath = path.join(
    testDirectory,
    'android',
    'app',
    'src',
    'main',
    'AndroidManifest.xml',
  );
  final File file = File(manifestPath);

  if (!file.existsSync()) {
    throw Exception('AndroidManifest.xml not found at $manifestPath');
  }

  final String xmlStr = file.readAsStringSync();
  final XmlDocument xmlDoc = XmlDocument.parse(xmlStr);
  final XmlElement applicationNode = xmlDoc.findAllElements('application').first;

  // Check if the meta-data node already exists.
  for (final (String key, String value) in keyPairs) {
    final Iterable<XmlElement> existingMetaData = applicationNode
        .findAllElements('meta-data')
        .where((XmlElement node) => node.getAttribute('android:name') == key);

    if (existingMetaData.isNotEmpty) {
      final XmlElement existingEntry = existingMetaData.first;
      existingEntry.setAttribute('android:value', value);
    } else {
      final XmlElement metaData = XmlElement(XmlName('meta-data'), <XmlAttribute>[
        XmlAttribute(XmlName('android:name'), key),
        XmlAttribute(XmlName('android:value'), value),
      ]);
      applicationNode.children.add(metaData);
    }
  }

  file.writeAsStringSync(xmlDoc.toXmlString(pretty: true, indent: '    '));
}
