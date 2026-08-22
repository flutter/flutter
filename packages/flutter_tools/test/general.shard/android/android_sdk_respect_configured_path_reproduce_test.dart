// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late Config config;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    config = Config.test();
  });

  group('AndroidSdk locateAndroidSdk', () {
    late File fallbackAdb;
    late File fallbackAapt;

    setUp(() {
      final Directory defaultSdkDir = fileSystem.directory('/default/android-sdk-path')..createSync(recursive: true);
      defaultSdkDir.childDirectory('licenses').createSync(recursive: true);
      defaultSdkDir.childDirectory('platform-tools').createSync(recursive: true);
      fallbackAdb = defaultSdkDir.childDirectory('platform-tools').childFile('adb')..createSync(recursive: true);
      fallbackAapt = defaultSdkDir.childDirectory('build-tools').childDirectory('23.0.2').childFile('aapt')..createSync(recursive: true);
    });

    testUsingContext(
      'respects ANDROID_HOME environment variable even if the directory lacks licenses or platform-tools',
      () {
        // Create the configured SDK directory, which has no platform-tools or licenses.
        final Directory configuredSdkDir = fileSystem.directory('/configured/android-sdk-path')..createSync(recursive: true);

        final AndroidSdk? sdk = AndroidSdk.locateAndroidSdk();

        expect(sdk, isNotNull);
        expect(sdk!.directory.path, configuredSdkDir.path);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => FakePlatform(
          environment: <String, String>{
            'ANDROID_HOME': '/configured/android-sdk-path',
          },
        ),
        Config: () => config,
        OperatingSystemUtils: () => _FakeOperatingSystemUtilsWithWhichAll(
          adb: fallbackAdb,
          aapt: fallbackAapt,
        ),
      },
    );
  });
}

class _FakeOperatingSystemUtilsWithWhichAll extends FakeOperatingSystemUtils {
  _FakeOperatingSystemUtilsWithWhichAll({required this.adb, required this.aapt});
  final File adb;
  final File aapt;

  @override
  List<File> whichAll(String execName) {
    if (execName == 'adb') {
      return <File>[adb];
    }
    if (execName == 'aapt') {
      return <File>[aapt];
    }
    return <File>[];
  }
}
