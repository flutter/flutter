// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    Cache.flutterRoot = getFlutterRoot();
    tempDir = createResolvedTempDirectorySync('gradle_merge_jni_libs_test.');
  });

  tearDown(() async {
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
    List<int> apkBytes = apkFile.readAsBytesSync();
    Archive archive = ZipDecoder().decodeBytes(apkBytes);
    return archive.findFile('lib/arm64-v8a/libapp.so') ??
        archive.findFile('lib/armeabi-v7a/libapp.so') ??
        archive.findFile('lib/x86_64/libapp.so');
  }

  // Reproduction test for https://github.com/flutter/flutter/issues/187553
  testWithoutContext('mergeJniLibFolders runs when Dart AOT source changes with flavors', () async {
    final Directory projectDir = tempDir.childDirectory('app');

    // 1. Create a Flutter app template.
    final ProcessResult createResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
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
      ...getLocalEngineArguments(),
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
      ...getLocalEngineArguments(),
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
