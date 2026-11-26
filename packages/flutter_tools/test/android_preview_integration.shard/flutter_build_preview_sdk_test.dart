// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDir;
  late String flutterBin;
  late Directory exampleAppDir;
  late Directory pluginDir;
  final compileSdkVersionMatch = RegExp(r'compileSdk\s*=?\s*[\w.]+');
  final String builtApkPath = <String>[
    'build',
    'app',
    'outputs',
    'flutter-apk',
    'app-debug.apk',
  ].join(platform.pathSeparator);

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
    flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    pluginDir = tempDir.childDirectory('aaa');
    exampleAppDir = pluginDir.childDirectory('example');

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

  test('build succeeds targeting string compileSdk', () async {
    final File buildGradleFile = exampleAppDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    // write a build.gradle.kts with compileSdk as preview("Baklava") which computes the preview compile sdk version
    buildGradleFile.writeAsStringSync(
      buildGradleFile.readAsStringSync().replaceFirst(compileSdkVersionMatch, '''
compileSdk {
  version = preview("Baklava")
}'''),
      flush: true,
    );
    expect(
      buildGradleFile.readAsStringSync(),
      contains('''
compileSdk {
  version = preview("Baklava")
}'''),
    );

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: exampleAppDir.path);
    expect(result, const ProcessResultMatcher());
    expect(
      exampleAppDir
          .childDirectory('build')
          .childDirectory('app')
          .childDirectory('outputs')
          .childDirectory('apk')
          .childDirectory('debug')
          .childFile('app-debug.apk')
          .existsSync(),
      true,
    );
    expect(result.stdout, contains('Built $builtApkPath'));
  });

  test('build succeeds targeting string compileSdkPreview', () async {
    final File buildGradleFile = exampleAppDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    // write a build.gradle.kts with compileSdkPreview as `Baklava` which is a string preview version
    buildGradleFile.writeAsStringSync(
      buildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "Baklava"',
      ),
      flush: true,
    );
    expect(buildGradleFile.readAsStringSync(), contains('compileSdkPreview = "Baklava"'));

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: exampleAppDir.path);
    expect(result, const ProcessResultMatcher());
    expect(
      exampleAppDir
          .childDirectory('build')
          .childDirectory('app')
          .childDirectory('outputs')
          .childDirectory('apk')
          .childDirectory('debug')
          .childFile('app-debug.apk')
          .existsSync(),
      true,
    );
    expect(result.stdout, contains('Built $builtApkPath'));
  });

  test('build succeeds when both example app and plugin target compileSdkPreview', () async {
    final File appBuildGradleFile = exampleAppDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    // write a build.gradle.kts with compileSdkPreview as `Baklava` which is a string preview version
    appBuildGradleFile.writeAsStringSync(
      appBuildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "Baklava"',
      ),
      flush: true,
    );
    expect(appBuildGradleFile.readAsStringSync(), contains('compileSdkPreview = "Baklava"'));

    final File pluginBuildGradleFile = pluginDir
        .childDirectory('android')
        .childFile('build.gradle.kts');
    // change the plugin build.gradle to use a preview compile sdk version
    pluginBuildGradleFile.writeAsStringSync(
      pluginBuildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "Baklava"',
      ),
      flush: true,
    );
    expect(pluginBuildGradleFile.readAsStringSync(), contains('compileSdkPreview = "Baklava"'));

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: exampleAppDir.path);
    expect(result, const ProcessResultMatcher());
    expect(
      exampleAppDir
          .childDirectory('build')
          .childDirectory('app')
          .childDirectory('outputs')
          .childDirectory('apk')
          .childDirectory('debug')
          .childFile('app-debug.apk')
          .existsSync(),
      true,
    );
    expect(result.stdout, contains('Built $builtApkPath'));
  });
}
