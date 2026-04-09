// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:standard_message_codec/standard_message_codec.dart' show StandardMessageCodec;

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;
const packageName = 'record_use_test_app';
const packageNameDependency = 'record_use_test_package';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }
  setUpAll(() async {
    processManager.runSync(<String>[flutterBin, 'config', '--enable-dart-data-assets']);
    processManager.runSync(<String>[flutterBin, 'config', '--enable-record-use']);
  });

  late Directory tempDirectory;
  late Directory appRoot;
  late Directory dependencyRoot;

  setUp(() async {
    // Do not reuse project structure to be able to make local changes
    tempDirectory = fileSystem.directory(
      fileSystem.systemTempDirectory.createTempSync().resolveSymbolicLinksSync(),
    );
    final Directory integrationTestsDir = tempDirectory
        .childDirectory('dev')
        .childDirectory('integration_tests');

    appRoot = integrationTestsDir.childDirectory(packageName);
    appRoot.createSync(recursive: true);
    copyTestProject(packageName, appRoot);

    dependencyRoot = integrationTestsDir.childDirectory(packageNameDependency);
    dependencyRoot.createSync(recursive: true);
    copyTestProject(packageNameDependency, dependencyRoot);
    await pinDependencies(dependencyRoot.childFile('pubspec.yaml'));

    expect(
      await processManager.run(<String>[
        flutterBin,
        'pub',
        'get',
      ], workingDirectory: dependencyRoot.path),
      const ProcessResultMatcher(),
    );
    expect(
      await processManager.run(<String>[flutterBin, 'pub', 'get'], workingDirectory: appRoot.path),
      const ProcessResultMatcher(),
    );
  });

  tearDown(() {
    tryToDelete(tempDirectory);
  });

  // TODO(dcharkes): Implement record-use in Flutter, this number should be two.
  const expectedTranslationCount = 4;

  group('record use', () {
    // This test relies on running the flutter app and capturing `print()`s
    // the app prints to determine if the test succeeded.
    // `flutter run --release` on the web doesn't support capturing
    // prints. See https://github.com/flutter/flutter/issues/159668
    // So this test only does `flutter run` for the hostOS.
    for (final device in <String>[hostOs]) {
      testWithoutContext('flutter run on $device --release', () async {
        final ProcessTestResult result = await runFlutter(
          <String>['run', '-v', '-d', device, '--release'],
          appRoot.path,
          <Transition>[
            Barrier.contains('Launching lib${Platform.pathSeparator}main.dart on'),
            Multiple.contains(
              <Pattern>[
                'Flutter run key command',

                // The translations are found.
                'HELLO: Ahoy!',
                'FRIEND: Matey',

                // The translations are tree-shaken.
                'COUNT: $expectedTranslationCount',
              ],
              handler: (_) {
                return 'q';
              },
            ),
            Barrier.contains('Application finished.'),
          ],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter run failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
      });
    }

    for (final target in <List<String>>[
      [hostOs],
      ['web'],
      ['web', '--wasm'],
    ]) {
      if (target.first == 'web') {
        // TODO(dcharkes): Fix compiler crash in dart2js, https://github.com/dart-lang/sdk/issues/63131.
        continue;
      }
      testWithoutContext('flutter build ${target.join(' ')} --release', () async {
        final ProcessTestResult result = await runFlutter(
          <String>['build', '-v', ...target, '--release'],
          appRoot.path,
          <Transition>[Barrier.contains('Built build${Platform.pathSeparator}${target.first}')],
        );
        if (result.exitCode != 0) {
          throw Exception(
            'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
          );
        }
        final Directory buildTargetDir = appRoot
            .childDirectory('build')
            .childDirectory(target.first);

        final List<File> manifestFiles = buildTargetDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('AssetManifest.bin'))
            .toList();

        if (manifestFiles.isEmpty) {
          throw Exception('Expected a `AssetManifest.bin` to be avilable in the $buildTargetDir.');
        }
        for (final manifestFile in manifestFiles) {
          final Uint8List manifestData = manifestFile.readAsBytesSync();
          final manifest =
              const StandardMessageCodec().decodeMessage(ByteData.sublistView(manifestData))
                  as Map<Object?, Object?>;
          const id1Key = 'packages/record_use_test_package/data/translations.json';
          expect(manifest.containsKey(id1Key), isTrue, reason: 'id1.json should be present');
          final File id1File = manifestFile.parent.childFile(id1Key);
          expect(id1File.existsSync(), isTrue);
          final translations = jsonDecode(id1File.readAsStringSync()) as Map<String, dynamic>;
          expect(translations.length, expectedTranslationCount);
        }
      });
    }
  });
}

void copyTestProject(String sourceName, Directory targetDirectory) {
  final Directory flutterRoot = fileSystem.directory(getFlutterRoot());
  final Directory sourceDirectory = flutterRoot
      .childDirectory('dev')
      .childDirectory('integration_tests')
      .childDirectory(sourceName);

  if (!sourceDirectory.existsSync()) {
    throw Exception('Source directory ${sourceDirectory.path} does not exist.');
  }

  for (final FileSystemEntity entity in sourceDirectory.listSync(recursive: true)) {
    final String relativePath = fileSystem.path.relative(entity.path, from: sourceDirectory.path);
    if (entity is Directory) {
      targetDirectory.childDirectory(relativePath).createSync(recursive: true);
    } else if (entity is File) {
      final File targetFile = targetDirectory.childFile(relativePath);
      targetFile.parent.createSync(recursive: true);
      entity.copySync(targetFile.path);
      if (relativePath == 'pubspec.yaml') {
        String content = targetFile.readAsStringSync();
        content = content.replaceFirst('resolution: workspace', '');
        targetFile.writeAsStringSync(content);
      }
    }
  }
}
