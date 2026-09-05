// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/environment/environment.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/fakes.dart';

void main() {
  late Config config;
  late MemoryFileSystem fs;

  setUp(() {
    config = Config.test();
    fs = MemoryFileSystem.test();
  });

  group(JavaCandidateLocator, () {
    testWithoutContext(
      'yields candidates in priority order: config -> studio -> javaHome -> path',
      () {
        config.setValue('jdk-dir', '/config/jdk');
        final androidStudio = _FakeAndroidStudio('/studio/jdk');
        final platform = FakePlatform(
          environment: <String, String>{Java.javaHomeEnvironmentVariable: '/env/jdk'},
        );

        final locator = JavaCandidateLocator(
          config: config,
          androidStudio: androidStudio,
          platform: platform,
        );

        final List<JavaHomeCandidate> candidates = locator.candidates.toList();
        expect(candidates.length, 4);
        expect(candidates[0].path, '/config/jdk');
        expect(candidates[0].source, JavaSource.flutterConfig);
        expect(candidates[1].path, '/studio/jdk');
        expect(candidates[1].source, JavaSource.androidStudio);
        expect(candidates[2].path, '/env/jdk');
        expect(candidates[2].source, JavaSource.javaHome);
        expect(candidates[3].path, null);
        expect(candidates[3].source, JavaSource.path);
      },
    );

    testWithoutContext('skips missing or empty sources', () {
      final platform = FakePlatform(
        environment: <String, String>{Java.javaHomeEnvironmentVariable: '/env/jdk'},
      );

      final locator = JavaCandidateLocator(
        config: config,
        androidStudio: _FakeAndroidStudio(null),
        platform: platform,
      );

      final List<JavaHomeCandidate> candidates = locator.candidates.toList();
      expect(candidates.length, 2);
      expect(candidates[0].path, '/env/jdk');
      expect(candidates[0].source, JavaSource.javaHome);
      expect(candidates[1].path, null);
      expect(candidates[1].source, JavaSource.path);
    });
  });

  group(SdkCandidateLocator, () {
    testWithoutContext('yields valid SDK directories in priority order', () {
      config.setValue('android-sdk', '/config/sdk');
      fs.directory('/config/sdk/platform-tools').createSync(recursive: true);

      final platform = FakePlatform(environment: <String, String>{'ANDROID_HOME': '/env/home_sdk'});
      fs.directory('/env/home_sdk/licenses').createSync(recursive: true);

      final locator = SdkCandidateLocator(
        config: config,
        platform: platform,
        fileSystem: fs,
        operatingSystemUtils: _FakeOperatingSystemUtils(),
        fileSystemUtils: _FakeFileSystemUtils('/home/user'),
      );

      final List<Directory> candidates = locator.candidates.toList();
      expect(candidates.length, 2);
      expect(candidates[0].path, '/config/sdk');
      expect(candidates[1].path, '/env/home_sdk');
    });
  });

  group(NdkCandidateLocator, () {
    testWithoutContext('yields SDK ndk/<version> subdirectories sorted descending by version', () {
      final Directory sdkRoot = fs.directory('/sdk')..createSync();
      final Directory ndkDir = sdkRoot.childDirectory('ndk')..createSync();
      ndkDir.childDirectory('25.1.8937393').createSync();
      ndkDir.childDirectory('27.0.12077973').createSync();
      ndkDir.childDirectory('26.1.10909125').createSync();

      final locator = NdkCandidateLocator(
        sdkRoot: sdkRoot,
        config: config,
        platform: FakePlatform(),
      );

      final List<Directory> candidates = locator.candidates.toList();
      expect(candidates.length, 3);
      expect(candidates[0].basename, '27.0.12077973');
      expect(candidates[1].basename, '26.1.10909125');
      expect(candidates[2].basename, '25.1.8937393');
    });
  });
}

class _FakeAndroidStudio extends Fake implements AndroidStudio {
  _FakeAndroidStudio(this._javaPath);
  final String? _javaPath;
  @override
  String? get javaPath => _javaPath;
}

class _FakeOperatingSystemUtils extends FakeOperatingSystemUtils {
  @override
  File? which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];
}

class _FakeFileSystemUtils extends Fake implements FileSystemUtils {
  _FakeFileSystemUtils(this._homeDirPath);
  final String? _homeDirPath;
  @override
  String? get homeDirPath => _homeDirPath;
}
