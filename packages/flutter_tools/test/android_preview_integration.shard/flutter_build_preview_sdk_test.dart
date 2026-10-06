// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../integration.shard/test_utils.dart';
import '../src/common.dart';

/// The Android preview SDK codename used by these tests.
///
/// This must be a preview of an API level that is at least
/// `FlutterExtension.compileSdkVersion`. Flutter libraries such as
/// `integration_test` compile against `flutter.compileSdkVersion`, and AGP 9
/// requires consumers to compile against the same or a higher API level.
///
/// The preview platform is provided on CI by the `android_sdk` CIPD package
/// pinned in the `Linux android_preview_tool_integration_tests` target in
/// `.ci.yaml`; keep the two in sync.
const previewCodename = 'CinnamonBun';

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
    // write a build.gradle.kts with compileSdk as preview(previewCodename) which computes the preview compile sdk version
    buildGradleFile.writeAsStringSync(
      buildGradleFile.readAsStringSync().replaceFirst(compileSdkVersionMatch, '''
compileSdk {
  version = preview("$previewCodename")
}'''),
      flush: true,
    );
    expect(
      buildGradleFile.readAsStringSync(),
      contains('''
compileSdk {
  version = preview("$previewCodename")
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
    // write a build.gradle.kts with compileSdkPreview as [previewCodename] which is a string preview version
    buildGradleFile.writeAsStringSync(
      buildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "$previewCodename"',
      ),
      flush: true,
    );
    expect(buildGradleFile.readAsStringSync(), contains('compileSdkPreview = "$previewCodename"'));

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
    // write a build.gradle.kts with compileSdkPreview as [previewCodename] which is a string preview version
    appBuildGradleFile.writeAsStringSync(
      appBuildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "$previewCodename"',
      ),
      flush: true,
    );
    expect(
      appBuildGradleFile.readAsStringSync(),
      contains('compileSdkPreview = "$previewCodename"'),
    );

    final File pluginBuildGradleFile = pluginDir
        .childDirectory('android')
        .childFile('build.gradle.kts');
    // change the plugin build.gradle to use a preview compile sdk version
    pluginBuildGradleFile.writeAsStringSync(
      pluginBuildGradleFile.readAsStringSync().replaceFirst(
        compileSdkVersionMatch,
        'compileSdkPreview = "$previewCodename"',
      ),
      flush: true,
    );
    expect(
      pluginBuildGradleFile.readAsStringSync(),
      contains('compileSdkPreview = "$previewCodename"'),
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
}
