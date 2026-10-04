// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart' show ProcessResultMatcher, fileSystem, flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

final String hostOs = platform.operatingSystem;
const packageName = 'record_use_test_app';
const packageNameDependency = 'record_use_test_package';

const expectedTranslationCount = 2;

void setUpAllRecordUse() {
  processManager.runSync(<String>[flutterBin, 'config', '--enable-dart-data-assets']);
  processManager.runSync(<String>[flutterBin, 'config', '--enable-record-use']);
}

late Directory tempDirectory;
late Directory appRoot;
late Directory dependencyRoot;

Future<void> setUpRecordUse() async {
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
}

void tearDownRecordUse() {
  tryToDelete(tempDirectory);
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
