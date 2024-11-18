// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(matanlurey): Remove after debugging https://github.com/flutter/flutter/issues/159000.
@Tags(<String>['flutter-build-apk'])
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';

import '../../src/common.dart';
import '../test_utils.dart' show flutterBin, platform;
import '../transition_test_utils.dart';
import 'native_assets_test_utils.dart';

const String packageName = 'package_with_native_assets';

/// The AGP versions to run these tests against.
final List<String> agpVersions = <String>[
  '8.4'
];

/// The build modes to target for each flutter command that supports passing
/// a build mode.
///
/// The flow of compiling kernel as well as bundling dylibs can differ based on
/// build mode, so we should cover this.
const List<String> buildModes = <String>[
  'debug',
  'profile',
  'release',
];

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    // TODO(dacoharkes): Implement Fuchsia. https://github.com/flutter/flutter/issues/129757
    return;
  }

  setUpAll(() {
    processManager.runSync(<String>[
      flutterBin,
      'config',
      '--enable-native-assets',
    ]);
  });

for (final String agpVersion in agpVersions) {
  for (final String buildMode in buildModes) {
      testWithoutContext('flutter build apk with native assets with build mode $buildMode and multiple flavors on AGP $agpVersion', () async {
        await inTempDir((Directory tempDirectory) async {
          final Directory packageDirectory = await createTestProject(packageName, tempDirectory);
          final Directory exampleDirectory = packageDirectory.childDirectory('example');

        File buildGradleFile = exampleDirectory.childDirectory('android').childFile('build.gradle');
        if (!buildGradleFile.existsSync()) {
          buildGradleFile = exampleDirectory.childDirectory('android').childFile('build.gradle.kts');
        }

        File appBuildGradleFile = exampleDirectory.childDirectory('android').childDirectory('app').childFile('build.gradle');
        if (!appBuildGradleFile.existsSync()) {
          appBuildGradleFile = exampleDirectory.childDirectory('android').childDirectory('app').childFile('build.gradle.kts');
        }

        expect(buildGradleFile, exists);
        expect(appBuildGradleFile, exists);

        // Use expected AGP version.
        final String buildGradle = buildGradleFile.readAsStringSync();
        final RegExp androidPluginRegExp =
            RegExp(r'com\.android\.tools\.build:gradle:(\d+\.\d+\.\d+)');
        final String newBuildGradle = buildGradle.replaceAll(
            androidPluginRegExp, 'com.android.tools.build:gradle:$agpVersion');
        buildGradleFile.writeAsStringSync(newBuildGradle);

        // Use Android app with multiple flavors.
        final String appBuildGradle = appBuildGradleFile.readAsStringSync().replaceAll('\r\n', '\n');
        final RegExp buildTypesBlockRegExp = RegExp(r'buildTypes {\n[ \t]+release {((.|\n)*)\n[ \t]+}\n[ \t]+}');
        final String buildTypesBlock = buildTypesBlockRegExp.firstMatch(appBuildGradle)!.toString();
        final String appBuildGradleSegmentDefiningFlavors = '''
    $buildTypesBlock

    flavorDimensions "mode"

    productFlavors {
        flavorOne {}
        flavorTwo {}
        flavorThree {}
    }
''';
        appBuildGradle.replaceFirst(
            buildTypesBlockRegExp, appBuildGradleSegmentDefiningFlavors);

          final ProcessResult result = processManager.runSync(
            <String>[
              flutterBin,
              'build',
              'apk',
              '--$buildMode',
            ],
            workingDirectory: exampleDirectory.path,
          );
          if (result.exitCode != 0) {
            throw Exception('flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}');
          }

          // Test that the native libraries are included as expected.
          final Directory nativeAssetsDir = exampleDirectory
            .childDirectory('build')
            .childDirectory('native_assets')
            .childDirectory('android')
            .childDirectory('jniLibs')
            .childDirectory('lib');
          expect(nativeAssetsDir, exists);

          // We expect one subdirectory for each Android architecture.
          expect(nativeAssetsDir.listSync().length, 4);
          expect(nativeAssetsDir..childDirectory('armeabi-v7a'), exists);
          expect(nativeAssetsDir..childDirectory('x86'), exists);
          expect(nativeAssetsDir..childDirectory('arm64-v8a'), exists);
          expect(nativeAssetsDir..childDirectory('x86_64'), exists);
        });
      });
    }
  }
}
