// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/io.dart' show InternetAddress, SocketException;

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('$Cache.checkLockAcquired', () {
    setUp(() {
      Cache.enableLocking();
    });

    tearDown(() {
      // Restore locking to prevent potential side-effects in
      // tests outside this group (this option is globally shared).
      Cache.enableLocking();
    });

    test('should throw when locking is not acquired', () {
      expect(() => Cache.checkLockAcquired(), throwsStateError);
    });

    test('should not throw when locking is disabled', () {
      Cache.disableLocking();
      Cache.checkLockAcquired();
    });

    testUsingContext('should not throw when lock is acquired', () async {
      await Cache.lock();
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      FileSystem: () => MockFileSystem(),
    });

    testUsingContext('should not throw when FLUTTER_ALREADY_LOCKED is set', () async {
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'},
    });
  });

  group('Cache', () {
    final MockCache mockCache = MockCache();
    final MemoryFileSystem fs = MemoryFileSystem();

    testUsingContext('Gradle wrapper should not be up to date, if some cached artifact is not available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      when(mockCache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      when(mockCache.getArtifactDirectory('gradle_wrapper')).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDate().isUpToDate, const UpdateResult(isUpToDate: false).isUpToDate);
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => fs,
    });

    testUsingContext('Gradle wrapper should be up to date, only if all cached artifact are available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew')).createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew.bat')).createSync(recursive: true);

      when(mockCache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      when(mockCache.getArtifactDirectory('gradle_wrapper')).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDate().isUpToDate, const UpdateResult(isUpToDate: true).isUpToDate);
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => fs,
    });

    test('should not be up to date, if some cached artifact is not', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: true, clobber: false));
      when(artifact2.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: false, clobber: false));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate().isUpToDate, isFalse);
    });
    test('should be up to date, if all cached artifacts are', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: true, clobber: false));
      when(artifact2.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: true, clobber: false));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate().isUpToDate, isTrue);
    });
    test('should update cached artifacts which are not up to date', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: true, clobber: false));
      when(artifact2.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: false, clobber: false));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      await cache.updateAll();
      verifyNever(artifact1.update(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown')));
      verify(artifact2.update(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'), clobber: anyNamed('clobber')));
    });
    testUsingContext('failed storage.googleapis.com download shows China warning', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: false, clobber: false));
      when(artifact2.isUpToDate(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'))).thenReturn(const UpdateResult(isUpToDate: false, clobber: false));
      final MockInternetAddress address = MockInternetAddress();
      when(address.host).thenReturn('storage.googleapis.com');
      when(artifact1.update(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'), clobber: anyNamed('clobber'))).thenThrow(SocketException(
        'Connection reset by peer',
        address: address,
      ));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      try {
        await cache.updateAll();
        fail('Mock thrown exception expected');
      } catch (e) {
        verify(artifact1.update(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'), clobber: anyNamed('clobber')));
        // Don't continue when retrieval fails.
        verifyNever(artifact2.update(buildModes: anyNamed('buildModes'), targetPlatforms: anyNamed('targetPlatforms'), skipUnknown: anyNamed('skipUnknown'), clobber: anyNamed('clobber')));
        expect(
          testLogger.errorText,
          contains('https://flutter.io/community/china'),
        );
      }
    });

    final MockPlatform macos = MockPlatform();
    final MockPlatform windows = MockPlatform();
    final MockPlatform linux = MockPlatform();
    when(macos.isMacOS).thenReturn(true);
    when(macos.isLinux).thenReturn(false);
    when(macos.isWindows).thenReturn(false);
    when(windows.isMacOS).thenReturn(false);
    when(windows.isLinux).thenReturn(false);
    when(windows.isWindows).thenReturn(true);
    when(linux.isMacOS).thenReturn(false);
    when(linux.isLinux).thenReturn(true);
    when(linux.isWindows).thenReturn(false);

    testUsingContext('Engine cache filtering - macOS', () {
      final FlutterEngine flutterEngine = FlutterEngine(MockCache());
      expect(flutterEngine.getBinaryDirs(
        buildModes: <BuildMode>[BuildMode.release],
        targetPlatforms: <TargetPlatform>[TargetPlatform.android_arm],
        skipUnknown: true,
      ), unorderedEquals(const <BinaryArtifact>[
        BinaryArtifact(
          name: 'common',
          fileName: 'flutter_patched_sdk.zip',
        ),
        BinaryArtifact(
          name: 'android-arm-release',
          fileName: 'android-arm-release/artifacts.zip',
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'android-arm-profile/darwin-x64',
          fileName: 'android-arm-profile/darwin-x64.zip',
          hostPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.profile,
          targetPlatform: TargetPlatform.android_arm,
          skipChecks: true,
        ),
        BinaryArtifact(
          name: 'android-arm-release/darwin-x64',
          fileName: 'android-arm-release/darwin-x64.zip',
          hostPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'darwin-x64',
          fileName: 'darwin-x64/artifacts.zip',
          hostPlatform: TargetPlatform.darwin_x64,
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: () => macos,
    });

    testUsingContext('Engine cache filtering - unknown mode - macOS', () {
      final FlutterEngine flutterEngine = FlutterEngine(MockCache());
      expect(flutterEngine.getBinaryDirs(
        buildModes: <BuildMode>[],
        targetPlatforms: <TargetPlatform>[TargetPlatform.ios],
        skipUnknown: true,
      ), unorderedEquals(const <BinaryArtifact>[
        BinaryArtifact(
          name: 'common',
          fileName: 'flutter_patched_sdk.zip',
        ),
        BinaryArtifact(
          name: 'android-arm-profile/darwin-x64',
          fileName: 'android-arm-profile/darwin-x64.zip',
          hostPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.profile,
          targetPlatform: TargetPlatform.android_arm,
          skipChecks: true,
        ),
        BinaryArtifact(
          name: 'ios', fileName: 'ios/artifacts.zip',
          buildMode: BuildMode.debug,
          hostPlatform: TargetPlatform.darwin_x64,
          targetPlatform: TargetPlatform.ios,
        ),
        BinaryArtifact(
          name: 'ios-profile',
          fileName: 'ios-profile/artifacts.zip',
          buildMode: BuildMode.profile,
          hostPlatform: TargetPlatform.darwin_x64,
          targetPlatform: TargetPlatform.ios,
        ),
        BinaryArtifact(
          name: 'ios-release',
          fileName: 'ios-release/artifacts.zip',
          buildMode: BuildMode.release,
          hostPlatform: TargetPlatform.darwin_x64,
          targetPlatform: TargetPlatform.ios,
        ),
        BinaryArtifact(
          name: 'darwin-x64',
          fileName: 'darwin-x64/artifacts.zip',
          hostPlatform: TargetPlatform.darwin_x64,
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: () => macos,
    });

    testUsingContext('Engine cache filtering - Windows', () {
      final FlutterEngine flutterEngine = FlutterEngine(MockCache());
      expect(flutterEngine.getBinaryDirs(
        buildModes: <BuildMode>[BuildMode.release],
        targetPlatforms: <TargetPlatform>[TargetPlatform.android_arm],
        skipUnknown: true,
      ), unorderedEquals(const <BinaryArtifact>[
          BinaryArtifact(
          name: 'common',
          fileName: 'flutter_patched_sdk.zip',
        ),
        BinaryArtifact(
          name: 'android-arm-release',
          fileName: 'android-arm-release/artifacts.zip',
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'android-arm-profile/windows-x64',
          fileName: 'android-arm-profile/windows-x64.zip',
          hostPlatform: TargetPlatform.windows_x64,
          buildMode: BuildMode.profile,
          targetPlatform: TargetPlatform.android_arm,
          skipChecks: true,
        ),
        BinaryArtifact(
          name: 'android-arm-release/windows-x64',
          fileName: 'android-arm-release/windows-x64.zip',
          hostPlatform: TargetPlatform.windows_x64,
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'windows-x64',
          fileName: 'windows-x64/artifacts.zip',
          hostPlatform: TargetPlatform.windows_x64,
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: () => windows,
    });

    testUsingContext('Engine cache filtering - linux', () {
      final FlutterEngine flutterEngine = FlutterEngine(MockCache());
      expect(flutterEngine.getBinaryDirs(
        buildModes: <BuildMode>[BuildMode.release],
        targetPlatforms: <TargetPlatform>[TargetPlatform.android_arm],
        skipUnknown: true,
      ), unorderedEquals(const <BinaryArtifact>[
          BinaryArtifact(
          name: 'common',
          fileName: 'flutter_patched_sdk.zip',
        ),
        BinaryArtifact(
          name: 'android-arm-release',
          fileName: 'android-arm-release/artifacts.zip',
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'android-arm-profile/linux-x64',
          fileName: 'android-arm-profile/linux-x64.zip',
          hostPlatform: TargetPlatform.linux_x64,
          buildMode: BuildMode.profile,
          targetPlatform: TargetPlatform.android_arm,
          skipChecks: true,
        ),
        BinaryArtifact(
          name: 'android-arm-release/linux-x64',
          fileName: 'android-arm-release/linux-x64.zip',
          hostPlatform: TargetPlatform.linux_x64,
          buildMode: BuildMode.release,
          targetPlatform: TargetPlatform.android_arm,
        ),
        BinaryArtifact(
          name: 'linux-x64',
          fileName: 'linux-x64/artifacts.zip',
          hostPlatform: TargetPlatform.linux_x64,
        ),
      ]));
    }, overrides: <Type, Generator>{
      Platform: () => linux,
    });
  });

  testUsingContext('flattenNameSubdirs', () {
    expect(flattenNameSubdirs(Uri.parse('http://flutter.io/foo/bar')), 'flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('http://docs.flutter.io/foo/bar')), 'docs.flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('https://www.flutter.io')), 'www.flutter.io');
  }, overrides: <Type, Generator>{
    FileSystem: () => MockFileSystem(),
  });
}

class MockFileSystem extends ForwardingFileSystem {
  MockFileSystem() : super(MemoryFileSystem());

  @override
  File file(dynamic path) {
    return MockFile();
  }
}

class MockFile extends Mock implements File {
  @override
  Future<RandomAccessFile> open({ FileMode mode = FileMode.read }) async {
    return MockRandomAccessFile();
  }
}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}
class MockCachedArtifact extends Mock implements CachedArtifact {}
class MockInternetAddress extends Mock implements InternetAddress {}
class MockCache extends Mock implements Cache {}
class MockPlatform extends Mock implements Platform {}
