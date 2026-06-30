// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression tests for `libapp.so` being dropped from the APK/app bundle, which
// surfaces either as a runtime "VM snapshot invalid" crash (APK) or as a
// "Release app bundle failed to strip debug symbols from native libraries"
// build failure (app bundle).
//
// Root cause: https://github.com/flutter/flutter/issues/186810 and
// https://github.com/flutter/flutter/issues/187388 (a regression from
// https://github.com/flutter/flutter/pull/181275, which moved `libapp.so` from
// a jar dependency onto a Flutter Gradle Plugin source-set `jniLibs` directory).
//
// These tests cover the two confirmed triggers:
//   * Case A: a combined `subprojects { ... evaluationDependsOn(":app") }` block
//     in the root `android/build.gradle.kts` together with a plugin whose Gradle
//     subproject name sorts alphabetically before `:app`. This evaluates `:app`
//     before its build directory is redirected.
//   * Case B: a flavored project where a build for a single ABI (e.g. a prior
//     `flutter run` on one device) leaves stale incremental state that drops
//     `libapp.so` for the other ABIs on the next multi-ABI build.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('flutter_libapp_so_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  String getTestFileString(String probe) {
    return '''
         import 'package:flutter/material.dart';

         void main() {
           print('$probe');
           runApp(const MyApp());
         }

         class MyApp extends StatelessWidget {
           const MyApp({super.key});

           @override
           Widget build(BuildContext context) {
             return const MaterialApp(
               home: Scaffold(
                 body: Center(
                   child: Text('Hello World'),
                 ),
               ),
             );
           }
         }
         ''';
  }

  ArchiveFile? getLibAppFile(File apkFile) {
    final List<int> apkBytes = apkFile.readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(apkBytes);
    return archive.findFile('lib/arm64-v8a/libapp.so') ??
        archive.findFile('lib/armeabi-v7a/libapp.so') ??
        archive.findFile('lib/x86_64/libapp.so');
  }

  test('libapp.so is packaged in an app bundle with a combined subprojects block '
      'and a plugin sorted before ":app"', () async {
    final Directory appDir = _createApp(tempDir);

    // A plugin whose Gradle subproject (":aaa_plugin") sorts before ":app", so
    // the combined subprojects loop reaches it (and triggers
    // evaluationDependsOn(":app")) before ":app"'s build dir is redirected.
    _createPlugin(tempDir, 'aaa_plugin');
    _addPathDependency(appDir, 'aaa_plugin', tempDir.childDirectory('aaa_plugin'));

    _useCombinedSubprojectsBlock(appDir);
    _disableR8(appDir);

    final ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      'build',
      'appbundle',
      '--release',
    ], workingDirectory: appDir.path);
    expect(
      result.exitCode,
      0,
      reason: 'flutter build appbundle --release failed:\n${result.stdout}\n${result.stderr}',
    );

    final List<String> files = _appBundleFileList(appDir, _releaseBundle(appDir));
    for (final arch in <String>['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
      expect(
        files,
        contains('base/lib/$arch/libapp.so'),
        reason: 'libapp.so missing for $arch in the app bundle',
      );
    }
  });

  test('libapp.so is packaged for every ABI after a single-ABI build of a flavored app', () async {
    final Directory appDir = _createApp(tempDir);
    _addFlavors(appDir, <String>['prod']);
    _disableR8(appDir);

    // Simulate a prior `flutter run` on a single-architecture device, which only
    // builds `app.so` for that ABI.
    final ProcessResult singleAbiBuild = processManager.runSync(<String>[
      flutterBin,
      'build',
      'apk',
      '--release',
      '--flavor',
      'prod',
      '--target-platform',
      'android-arm64',
    ], workingDirectory: appDir.path);
    expect(
      singleAbiBuild.exitCode,
      0,
      reason: 'single-ABI build failed:\n${singleAbiBuild.stdout}\n${singleAbiBuild.stderr}',
    );

    // Now build for all ABIs. `libapp.so` must be present for all of them, not
    // just the one built above.
    final ProcessResult allAbiBuild = processManager.runSync(<String>[
      flutterBin,
      'build',
      'appbundle',
      '--release',
      '--flavor',
      'prod',
    ], workingDirectory: appDir.path);
    expect(
      allAbiBuild.exitCode,
      0,
      reason: 'multi-ABI build failed:\n${allAbiBuild.stdout}\n${allAbiBuild.stderr}',
    );

    final List<String> files = _appBundleFileList(
      appDir,
      appDir
          .childDirectory('build')
          .childDirectory('app')
          .childDirectory('outputs')
          .childDirectory('bundle')
          .childDirectory('prodRelease')
          .childFile('app-prod-release.aab'),
    );
    for (final arch in <String>['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
      expect(
        files,
        contains('base/lib/$arch/libapp.so'),
        reason: 'libapp.so missing for $arch after a single-ABI build preceded the multi-ABI build',
      );
    }
  });

  // Reproduction test for https://github.com/flutter/flutter/issues/187553
  testWithoutContext('mergeJniLibFolders runs when Dart AOT source changes with flavors', () async {
    final Directory projectDir = tempDir.childDirectory('app');

    // 1. Create a Flutter app template.
    final ProcessResult createResult = processManager.runSync(<String>[
      flutterBin,
      'create',
      '--template=app',
      '--platforms=android',
      'app',
    ], workingDirectory: tempDir.path);
    expect(createResult, const ProcessResultMatcher());

    // 2. Add product flavors to build.gradle.kts.
    final File buildGradleFile = projectDir
        .childDirectory('android/app')
        .childFile('build.gradle.kts');
    expect(buildGradleFile, exists);
    String buildGradleContents = buildGradleFile.readAsStringSync();
    buildGradleContents = buildGradleContents.replaceFirst('android {', '''
android {
    flavorDimensions += "default"
    productFlavors {
        create("prod") {
            dimension = "default"
        }
        create("dev") {
            dimension = "default"
        }
    }''');
    buildGradleFile.writeAsStringSync(buildGradleContents);

    const PROBE_A = 'probe-AAAA';
    const PROBE_B = 'probe-BBBB';
    // 3. Configure main.dart with probe-AAAA.
    final File mainDartFile = projectDir.childDirectory('lib').childFile('main.dart');
    expect(mainDartFile, exists);
    mainDartFile.writeAsStringSync(getTestFileString(PROBE_A));

    // 4. Build APK with flavor prod (Build 1).
    final ProcessResult build1Result = processManager.runSync(<String>[
      flutterBin,
      'build',
      'apk',
      '--release',
      '--flavor',
      'prod',
    ], workingDirectory: projectDir.path);
    expect(build1Result, const ProcessResultMatcher());

    // Verify APK contains probe-AAAA.
    final File apkFile = projectDir
        .childDirectory('build/app/outputs/flutter-apk')
        .childFile('app-prod-release.apk');
    expect(apkFile, exists);

    ArchiveFile? libappFile = getLibAppFile(apkFile);
    expect(libappFile, isNotNull);
    String libappContent = latin1.decode(libappFile!.content as List<int>, allowInvalid: true);
    expect(libappContent.contains(PROBE_A), isTrue);
    expect(libappContent.contains(PROBE_B), isFalse);

    // 5. Change main.dart to probe-BBBB.
    mainDartFile.writeAsStringSync(getTestFileString(PROBE_B));

    // 6. Build APK with flavor prod (Build 2 - incremental).
    final ProcessResult build2Result = processManager.runSync(<String>[
      flutterBin,
      'build',
      'apk',
      '--release',
      '--flavor',
      'prod',
    ], workingDirectory: projectDir.path);
    expect(build2Result, const ProcessResultMatcher());

    // Verify APK contains probe-BBBB and NOT probe-AAAA.
    libappFile = getLibAppFile(apkFile);
    expect(libappFile, isNotNull);
    libappContent = latin1.decode(libappFile!.content as List<int>, allowInvalid: true);
    expect(libappContent.contains('probe-BBBB'), isTrue);
    expect(libappContent.contains('probe-AAAA'), isFalse);
  });
}

Directory _createApp(Directory workingDir) {
  final ProcessResult result = processManager.runSync(<String>[
    flutterBin,
    'create',
    '--template=app',
    '--platforms=android',
    'app',
  ], workingDirectory: workingDir.path);
  if (result.exitCode != 0) {
    throw StateError('flutter create app failed:\n${result.stdout}\n${result.stderr}');
  }
  return workingDir.childDirectory('app');
}

void _createPlugin(Directory workingDir, String name) {
  final ProcessResult result = processManager.runSync(<String>[
    flutterBin,
    'create',
    '--template=plugin',
    '--platforms=android',
    name,
  ], workingDirectory: workingDir.path);
  if (result.exitCode != 0) {
    throw StateError('flutter create plugin failed:\n${result.stdout}\n${result.stderr}');
  }
}

void _addPathDependency(Directory appDir, String name, Directory packageDir) {
  final File pubspec = appDir.childFile('pubspec.yaml');
  final String contents = pubspec.readAsStringSync();
  // Insert the path dependency immediately under the `dependencies:` key.
  final String updated = contents.replaceFirst(
    RegExp(r'^dependencies:\s*$', multiLine: true),
    'dependencies:\n  $name:\n    path: ${packageDir.path.replaceAll(r'\', '/')}',
  );
  if (updated == contents) {
    throw StateError('Failed to add path dependency to ${pubspec.path}');
  }
  pubspec.writeAsStringSync(updated);
}

/// Rewrites the two separate `subprojects { ... }` blocks generated by the app
/// template into the single combined block that triggers the regression.
void _useCombinedSubprojectsBlock(Directory appDir) {
  final File buildGradle = appDir.childDirectory('android').childFile('build.gradle.kts');
  final String contents = buildGradle.readAsStringSync().replaceAll('\r\n', '\n');
  const separateBlocks = '''
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}''';
  const combinedBlock = '''
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}''';
  if (!contents.contains(separateBlocks)) {
    throw StateError(
      'Could not find the expected separate subprojects blocks in ${buildGradle.path}.\n'
      'Template may have changed; update this test.',
    );
  }
  buildGradle.writeAsStringSync(contents.replaceFirst(separateBlocks, combinedBlock));
}

void _addFlavors(Directory appDir, List<String> flavors) {
  final File buildGradle = appDir
      .childDirectory('android')
      .childDirectory('app')
      .childFile('build.gradle.kts');
  final String contents = buildGradle.readAsStringSync();
  final buffer = StringBuffer()
    ..writeln('    flavorDimensions += "env"')
    ..writeln('    productFlavors {');
  for (final flavor in flavors) {
    buffer
      ..writeln('        create("$flavor") {')
      ..writeln('            dimension = "env"')
      ..writeln('        }');
  }
  buffer.writeln('    }');
  // Insert the product flavors at the start of the `android { ... }` block.
  final String updated = contents.replaceFirst(
    RegExp(r'^android\s*\{', multiLine: true),
    'android {\n$buffer',
  );
  if (updated == contents) {
    throw StateError('Failed to add product flavors to ${buildGradle.path}');
  }
  buildGradle.writeAsStringSync(updated);
}

void _disableR8(Directory appDir) {
  final File buildGradle = appDir
      .childDirectory('android')
      .childDirectory('app')
      .childFile('build.gradle.kts');
  final String contents = buildGradle.readAsStringSync();
  final String updated = contents.replaceFirst(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("debug")\n            isMinifyEnabled = false\n            isShrinkResources = false',
  );
  if (updated == contents) {
    throw StateError('Failed to disable R8 in ${buildGradle.path}');
  }
  buildGradle.writeAsStringSync(updated);
}

File _releaseBundle(Directory appDir) => appDir
    .childDirectory('build')
    .childDirectory('app')
    .childDirectory('outputs')
    .childDirectory('bundle')
    .childDirectory('release')
    .childFile('app-release.aab');

/// Returns the file entries inside [appBundle] using `apkanalyzer files list`.
List<String> _appBundleFileList(Directory appDir, File appBundle) {
  if (!appBundle.existsSync()) {
    throw StateError('App bundle not found at ${appBundle.path}');
  }
  final File localProperties = appDir.childDirectory('android').childFile('local.properties');
  final RegExpMatch? match = RegExp(
    r'sdk\.dir=(.+)',
  ).firstMatch(localProperties.readAsStringSync());
  final String sdkPath = match?.group(1)?.trim() ?? '';
  if (sdkPath.isEmpty) {
    throw StateError('SDK path not found in ${localProperties.path}');
  }
  final String apkAnalyzer = fileSystem
      .directory(sdkPath)
      .childDirectory('cmdline-tools')
      .childDirectory('latest')
      .childDirectory('bin')
      .childFile(Platform.isWindows ? 'apkanalyzer.bat' : 'apkanalyzer')
      .path;

  final ProcessResult result = processManager.runSync(<String>[
    apkAnalyzer,
    'files',
    'list',
    appBundle.path,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      apkAnalyzer,
      <String>['files', 'list', appBundle.path],
      'apkanalyzer failed:\n${result.stderr}',
      result.exitCode,
    );
  }
  // apkanalyzer prints entries like `/base/lib/arm64-v8a/libapp.so`; normalize
  // by trimming the leading slash.
  return result.stdout
      .toString()
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .map((String line) => line.startsWith('/') ? line.substring(1) : line)
      .toList();
}
