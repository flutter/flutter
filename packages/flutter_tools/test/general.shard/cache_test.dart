// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show InternetAddress, SocketException;
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/os.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group('$Cache.checkLockAcquired', () {
    MockFileSystem mockFileSystem;
    MemoryFileSystem memoryFileSystem;
    MockFile mockFile;
    MockRandomAccessFile mockRandomAccessFile;

    setUp(() {
      mockFileSystem = MockFileSystem();
      memoryFileSystem = MemoryFileSystem();
      mockFile = MockFile();
      mockRandomAccessFile = MockRandomAccessFile();
      when(mockFileSystem.path).thenReturn(memoryFileSystem.path);

      Cache.enableLocking();
    });

    tearDown(() {
      // Restore locking to prevent potential side-effects in
      // tests outside this group (this option is globally shared).
      Cache.enableLocking();
      Cache.releaseLockEarly();
    });

    test('should throw when locking is not acquired', () {
      expect(() => Cache.checkLockAcquired(), throwsStateError);
    });

    test('should not throw when locking is disabled', () {
      Cache.disableLocking();
      Cache.checkLockAcquired();
    });

    testUsingContext('should not throw when lock is acquired', () async {
      when(mockFileSystem.file(argThat(endsWith('lockfile')))).thenReturn(mockFile);
      when(mockFile.openSync(mode: anyNamed('mode'))).thenReturn(mockRandomAccessFile);
      await Cache.lock();
      Cache.checkLockAcquired();
      Cache.releaseLockEarly();
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
    });

    testUsingContext('throws tool exit when lockfile open fails', () async {
      when(mockFileSystem.file(argThat(endsWith('lockfile')))).thenReturn(mockFile);
      when(mockFile.openSync(mode: anyNamed('mode'))).thenThrow(const FileSystemException());
      expect(() async => await Cache.lock(), throwsA(isA<ToolExit>()));
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
    });

    testUsingContext('should not throw when FLUTTER_ALREADY_LOCKED is set', () async {
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'},
    });
  });

  group('Cache', () {
    MockCache mockCache;
    MemoryFileSystem memoryFileSystem;

    setUp(() {
      mockCache = MockCache();
      memoryFileSystem = MemoryFileSystem();
    });

    testUsingContext('Gradle wrapper should not be up to date, if some cached artifact is not available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      when(mockCache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('Gradle wrapper should be up to date, only if all cached artifact are available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew')).createSync(recursive: true);
      fs.file(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew.bat')).createSync(recursive: true);

      when(mockCache.getCacheDir(fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(fs.directory(fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDateInner(), true);
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => memoryFileSystem,
    });

    test('should not be up to date, if some cached artifact is not', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isFalse);
    });
    test('should be up to date, if all cached artifacts are', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(true);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isTrue);
    });
    test('should update cached artifacts which are not up to date', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      await cache.updateAll(<DevelopmentArtifact>{
        null,
      });
      verifyNever(artifact1.update());
      verify(artifact2.update());
    });
    testUsingContext('getter dyLdLibEntry concatenates the output of each artifact\'s dyLdLibEntry getter', () async {
      final IosUsbArtifacts artifact1 = MockIosUsbArtifacts();
      final IosUsbArtifacts artifact2 = MockIosUsbArtifacts();
      final IosUsbArtifacts artifact3 = MockIosUsbArtifacts();
      when(artifact1.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/alpha:/path/to/beta',
          });
      when(artifact2.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/gamma:/path/to/delta:/path/to/epsilon',
          });
      when(artifact3.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '',
          });
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2, artifact3]);

      expect(cache.dyLdLibEntry.key, 'DYLD_LIBRARY_PATH');
      expect(
        cache.dyLdLibEntry.value,
        '/path/to/alpha:/path/to/beta:/path/to/gamma:/path/to/delta:/path/to/epsilon',
      );
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
    });
    testUsingContext('failed storage.googleapis.com download shows China warning', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(false);
      when(artifact2.isUpToDate()).thenReturn(false);
      final MockInternetAddress address = MockInternetAddress();
      when(address.host).thenReturn('storage.googleapis.com');
      when(artifact1.update()).thenThrow(SocketException(
        'Connection reset by peer',
        address: address,
      ));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      try {
        await cache.updateAll(<DevelopmentArtifact>{
          null,
        });
        fail('Mock thrown exception expected');
      } catch (e) {
        verify(artifact1.update());
        // Don't continue when retrieval fails.
        verifyNever(artifact2.update());
        expect(
          testLogger.errorText,
          contains('https://flutter.dev/community/china'),
        );
      }
    });
  });

  testUsingContext('flattenNameSubdirs', () {
    expect(flattenNameSubdirs(Uri.parse('http://flutter.dev/foo/bar')), 'flutter.dev/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('http://docs.flutter.io/foo/bar')), 'docs.flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('https://www.flutter.dev')), 'www.flutter.dev');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });

  test('Unstable artifacts', () {
    expect(DevelopmentArtifact.web.unstable, true);
    expect(DevelopmentArtifact.linux.unstable, true);
    expect(DevelopmentArtifact.macOS.unstable, true);
    expect(DevelopmentArtifact.windows.unstable, true);
    expect(DevelopmentArtifact.fuchsia.unstable, true);
    expect(DevelopmentArtifact.flutterRunner.unstable, true);
  });

  group('EngineCachedArtifact', () {
    FakeHttpClient fakeHttpClient;
    FakePlatform fakePlatform;
    MemoryFileSystem memoryFileSystem;
    MockCache mockCache;
    MockOperatingSystemUtils mockOperatingSystemUtils;

    setUp(() {
      fakeHttpClient = FakeHttpClient();
      fakePlatform = FakePlatform()..environment = const <String, String>{};
      memoryFileSystem = MemoryFileSystem();
      mockCache = MockCache();
      mockOperatingSystemUtils = MockOperatingSystemUtils();
      when(mockOperatingSystemUtils.verifyZip(any)).thenReturn(true);
    });

    testUsingContext('makes binary dirs readable and executable by all', () async {
      final Directory artifactDir = fs.systemTempDirectory.createTempSync('flutter_cache_test_artifact.');
      final Directory downloadDir = fs.systemTempDirectory.createTempSync('flutter_cache_test_download.');
      when(mockCache.getArtifactDirectory(any)).thenReturn(artifactDir);
      when(mockCache.getDownloadDir()).thenReturn(downloadDir);
      final FakeCachedArtifact artifact = FakeCachedArtifact(
        cache: mockCache,
        binaryDirs: <List<String>>[
          <String>['bin_dir', 'unused_url_path'],
        ],
        requiredArtifacts: DevelopmentArtifact.universal,
      );
      await artifact.updateInner();
      final Directory dir = memoryFileSystem.systemTempDirectory
          .listSync(recursive: true)
          .whereType<Directory>()
          .singleWhere((Directory directory) => directory.basename == 'bin_dir', orElse: () => null);
      expect(dir, isNotNull);
      expect(dir.path, artifactDir.childDirectory('bin_dir').path);
      verify(mockOperatingSystemUtils.chmod(argThat(hasPath(dir.path)), 'a+r,a+x'));
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => memoryFileSystem,
      HttpClientFactory: () => () => fakeHttpClient,
      OperatingSystemUtils: () => mockOperatingSystemUtils,
      Platform: () => fakePlatform,
    });
  });

  group('AndroidMavenArtifacts', () {
    MemoryFileSystem memoryFileSystem;
    MockProcessManager processManager;
    MockCache mockCache;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      processManager = MockProcessManager();
      mockCache = MockCache();
    });

    test('development artifact', () async {
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts();
      expect(mavenArtifacts.developmentArtifact, DevelopmentArtifact.androidMaven);
    });

    testUsingContext('update', () async {
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts();
      expect(mavenArtifacts.isUpToDate(), isFalse);

      final Directory gradleWrapperDir = fs.systemTempDirectory.createTempSync('flutter_cache_test_gradle_wrapper.');
      when(mockCache.getArtifactDirectory('gradle_wrapper')).thenReturn(gradleWrapperDir);

      fs.directory(gradleWrapperDir.childDirectory('gradle').childDirectory('wrapper'))
          .createSync(recursive: true);
      fs.file(fs.path.join(gradleWrapperDir.path, 'gradlew')).writeAsStringSync('irrelevant');
      fs.file(fs.path.join(gradleWrapperDir.path, 'gradlew.bat')).writeAsStringSync('irrelevant');

      when(processManager.run(any, environment: captureAnyNamed('environment')))
        .thenAnswer((Invocation invocation) {
          final List<String> args = invocation.positionalArguments[0];
          expect(args.length, 6);
          expect(args[1], '-b');
          expect(args[2].endsWith('resolve_dependencies.gradle'), isTrue);
          expect(args[5], 'resolveDependencies');
          expect(invocation.namedArguments[#environment], gradleEnv);
          return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
        });

      await mavenArtifacts.update();

      expect(mavenArtifacts.isUpToDate(), isFalse);
    }, overrides: <Type, Generator>{
      Cache: ()=> mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => processManager,
    });
  });
}

class FakeCachedArtifact extends EngineCachedArtifact {
  FakeCachedArtifact({
    String stampName = 'STAMP',
    @required Cache cache,
    DevelopmentArtifact requiredArtifacts,
    this.binaryDirs = const <List<String>>[],
    this.licenseDirs = const <String>[],
    this.packageDirs = const <String>[],
  }) : super(stampName, cache, requiredArtifacts);

  final List<List<String>> binaryDirs;
  final List<String> licenseDirs;
  final List<String> packageDirs;

  @override
  List<List<String>> getBinaryDirs() => binaryDirs;

  @override
  List<String> getLicenseDirs() => licenseDirs;

  @override
  List<String> getPackageDirs() => packageDirs;
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
class MockDirectory extends Mock implements Directory {}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}
class MockCachedArtifact extends Mock implements CachedArtifact {}
class MockIosUsbArtifacts extends Mock implements IosUsbArtifacts {}
class MockInternetAddress extends Mock implements InternetAddress {}
class MockCache extends Mock implements Cache {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
