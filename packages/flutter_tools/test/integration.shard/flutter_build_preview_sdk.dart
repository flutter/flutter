// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late String flutterBin;
  late Directory exampleAppDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    exampleAppDir = tempDir.childDirectory('aaa').childDirectory('example');

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'aaa',
    ], workingDirectory: tempDir.path);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test(
    'build succeeds targeting string compileSdkVersion',
    () async {
      final File buildGradleFile = exampleAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
      // write a build.gradle with compileSdkVersion as `android-Tiramisu` which is a string preview version
      buildGradleFile.writeAsStringSync(
        buildGradleFile.readAsStringSync().replaceFirst('compileSdkVersion flutter.compileSdkVersion', 'compileSdkVersion "android-Tiramisu"'),
        flush: true
      );
      expect(buildGradleFile.readAsStringSync(), contains('compileSdkVersion "android-Tiramisu"'));

      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'apk',
        '--debug',
      ], workingDirectory: exampleAppDir.path);
      expect(result.stdout, contains('Built build/app/outputs/flutter-apk/app-debug.apk.'));
      expect(exampleAppDir.childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('apk')
        .childDirectory('debug')
        .childFile('app-debug.apk').existsSync(), true);
    },
  );

  test(
    'build succeeds targeting string compileSdkPreview',
    () async {
      final File buildGradleFile = exampleAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
      // write a build.gradle with compileSdkPreview as `Tiramisu` which is a string preview version
      buildGradleFile.writeAsStringSync(
        buildGradleFile.readAsStringSync().replaceFirst('compileSdkVersion flutter.compileSdkVersion', 'compileSdkPreview "Tiramisu"'),
        flush: true
      );
      expect(buildGradleFile.readAsStringSync(), contains('compileSdkPreview "Tiramisu"'));

      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'apk',
        '--debug',
      ], workingDirectory: exampleAppDir.path);
      expect(result.stdout, contains('Built build/app/outputs/flutter-apk/app-debug.apk.'));
      expect(exampleAppDir.childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('apk')
        .childDirectory('debug')
        .childFile('app-debug.apk').existsSync(), true);
    },
  );
}
