// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(minutes: 15))
library;

import 'package:archive/archive.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

/// The names of the files in the APK at [apkPath], relative to [hostAppDir].
List<String> apkEntries(Directory hostAppDir, String apkPath) {
  final File apkFile = hostAppDir.childFile(apkPath);
  expect(apkFile, exists);
  return <String>[
    for (final ArchiveFile file in ZipDecoder().decodeBytes(apkFile.readAsBytesSync())) file.name,
  ];
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('android_add_to_app_module_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testWithoutContext('A host app with android.newDsl=true packages the Flutter build of the module variant it consumes', () async {
    final ProcessResult createResult = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=module',
      'hello',
    ], workingDirectory: tempDir.path);
    expect(createResult, const ProcessResultMatcher());
    final Directory moduleAndroidDir = tempDir.childDirectory('hello').childDirectory('.android');

    // The host's settings.gradle includes the module from the sibling `hello` directory.
    final Directory hostAppDir = tempDir.childDirectory('host')..createSync();
    copyDirectory(
      fileSystem
          .directory(getFlutterRoot())
          .childDirectory('dev')
          .childDirectory('integration_tests')
          .childDirectory('module_host_with_custom_build_v2_embedding'),
      hostAppDir,
    );
    final gradlew = platform.isWindows ? 'gradlew.bat' : 'gradlew';
    moduleAndroidDir.childFile(gradlew).copySync(hostAppDir.childFile(gradlew).path);
    final String wrapperJarPath = fileSystem.path.join('gradle', 'wrapper', 'gradle-wrapper.jar');
    moduleAndroidDir.childFile(wrapperJarPath).copySync(hostAppDir.childFile(wrapperJarPath).path);
    if (!platform.isWindows) {
      final ProcessResult chmodResult = await processManager.run(<String>[
        'chmod',
        '+x',
        hostAppDir.childFile(gradlew).path,
      ]);
      expect(chmodResult, const ProcessResultMatcher());
    }

    // Builds with `android.newDsl=true`, where AGP does not provide the variant API
    // that `libraryVariants` and `applicationVariants` belong to, and with AGP's
    // compatibility mode off.
    // `flutter.hostAppProjectName` has no effect; setting it must only log a warning.
    final File gradleProperties = hostAppDir.childFile('gradle.properties');
    gradleProperties.writeAsStringSync(
      gradleProperties.readAsStringSync().replaceFirst(
        'android.newDsl=false',
        'android.newDsl=true',
      ),
    );
    gradleProperties.writeAsStringSync(
      '\nandroid.compatibility.enableLegacyApi=false\nflutter.hostAppProjectName=app\n',
      mode: FileMode.append,
    );
    expect(gradleProperties.readAsStringSync(), contains('android.newDsl=true'));

    // `staging` is debuggable and falls back to the module's `debug` variant (see the
    // fixture). `qa` is debuggable too, but falls back to the module's `release` variant,
    // so it must get release Flutter artifacts.
    hostAppDir.childDirectory('app').childFile('build.gradle').writeAsStringSync('''

android {
    buildTypes {
        qa {
            initWith debug
            matchingFallbacks += 'release'
        }
    }
}
''', mode: FileMode.append);

    // Each host task runs on its own. With a single task on the command line, Flutter only
    // configures the application variants that task builds, which must not apply to the
    // module's variants: no host task name matches the module variant it consumes.
    Future<List<String>> buildHostApk(String task, String apkPath) async {
      final ProcessResult buildResult = await processManager.run(<String>[
        hostAppDir.childFile(gradlew).path,
        task,
      ], workingDirectory: hostAppDir.path);
      expect(buildResult, const ProcessResultMatcher());
      expect(
        buildResult.stdout,
        contains("The Gradle property 'flutter.hostAppProjectName' has no effect."),
      );
      return apkEntries(hostAppDir, apkPath);
    }

    final List<String> stagingEntries = await buildHostApk(
      'app:assembleDemoStaging',
      'app/build/outputs/apk/demo/staging/app-demo-staging.apk',
    );
    expect(stagingEntries, contains('assets/flutter_assets/AssetManifest.bin'));
    expect(stagingEntries, contains('assets/flutter_assets/kernel_blob.bin'));
    expect(stagingEntries, isNot(contains('lib/arm64-v8a/libapp.so')));

    final List<String> qaEntries = await buildHostApk(
      'app:assembleDemoQa',
      'app/build/outputs/apk/demo/qa/app-demo-qa.apk',
    );
    expect(qaEntries, contains('assets/flutter_assets/AssetManifest.bin'));
    expect(qaEntries, contains('lib/arm64-v8a/libapp.so'));
    expect(qaEntries, isNot(contains('assets/flutter_assets/kernel_blob.bin')));
  });
}
