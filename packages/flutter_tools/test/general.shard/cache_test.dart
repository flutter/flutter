// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show InternetAddress, SocketException;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

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
      Cache.releaseLock();
    });

    test('should throw when locking is not acquired', () {
      expect(Cache.checkLockAcquired, throwsStateError);
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
      Cache.releaseLock();
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws tool exit when lockfile open fails', () async {
      when(mockFileSystem.file(argThat(endsWith('lockfile')))).thenReturn(mockFile);
      when(mockFile.openSync(mode: anyNamed('mode'))).thenThrow(const FileSystemException());
      expect(() async => await Cache.lock(), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
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

    testUsingContext('Continues on failed stamp file update', () async {
      final Directory artifactDir = globals.fs.systemTempDirectory.createTempSync('flutter_cache_test_artifact.');
      final Directory downloadDir = globals.fs.systemTempDirectory.createTempSync('flutter_cache_test_download.');
      when(mockCache.getArtifactDirectory(any)).thenReturn(artifactDir);
      when(mockCache.getDownloadDir()).thenReturn(downloadDir);
      when(mockCache.setStampFor(any, any)).thenAnswer((_) {
        throw const FileSystemException('stamp write failed');
      });
      final FakeSimpleArtifact artifact = FakeSimpleArtifact(mockCache);
      await artifact.update(MockArtifactUpdater());
      expect(testLogger.errorText, contains('stamp write failed'));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Gradle wrapper should not be up to date, if some cached artifact is not available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = globals.fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      when(mockCache.getCacheDir(globals.fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(globals.fs.directory(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Gradle wrapper should be up to date, only if all cached artifact are available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(mockCache);
      final Directory directory = globals.fs.directory('/Applications/flutter/bin/cache');
      directory.createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper', 'gradlew.bat')).createSync(recursive: true);

      when(mockCache.getCacheDir(globals.fs.path.join('artifacts', 'gradle_wrapper'))).thenReturn(globals.fs.directory(globals.fs.path.join(directory.path, 'artifacts', 'gradle_wrapper')));
      expect(gradleWrapper.isUpToDateInner(), true);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('should not be up to date, if some cached artifact is not', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('should be up to date, if all cached artifacts are', () {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(true);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(cache.isUpToDate(), isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('should update cached artifacts which are not up to date', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(true);
      when(artifact2.isUpToDate()).thenReturn(false);
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      await cache.updateAll(<DevelopmentArtifact>{
        null,
      });
      verifyNever(artifact1.update(any));
      verify(artifact2.update(any));
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext("getter dyLdLibEntry concatenates the output of each artifact's dyLdLibEntry getter", () async {
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
      Cache: () => mockCache,
    });
    testUsingContext('failed storage.googleapis.com download shows China warning', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenReturn(false);
      when(artifact2.isUpToDate()).thenReturn(false);
      final MockInternetAddress address = MockInternetAddress();
      when(address.host).thenReturn('storage.googleapis.com');
      when(artifact1.update(any)).thenThrow(SocketException(
        'Connection reset by peer',
        address: address,
      ));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      try {
        await cache.updateAll(<DevelopmentArtifact>{
          null,
        });
        fail('Mock thrown exception expected');
      } on Exception {
        verify(artifact1.update(any));
        // Don't continue when retrieval fails.
        verifyNever(artifact2.update(any));
        expect(
          testLogger.errorText,
          contains('https://flutter.dev/community/china'),
        );
      }
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('Invalid URI for FLUTTER_STORAGE_BASE_URL throws ToolExit', () async {
      final Cache cache = Cache();

      expect(() => cache.storageBaseUrl, throwsToolExit());
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_STORAGE_BASE_URL': ' http://foo',
      }),
    });
  });

  testWithoutContext('flattenNameSubdirs', () {
    expect(flattenNameSubdirs(Uri.parse('http://flutter.dev/foo/bar'), MemoryFileSystem()), 'flutter.dev/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('http://docs.flutter.io/foo/bar'), MemoryFileSystem()), 'docs.flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('https://www.flutter.dev'), MemoryFileSystem()), 'www.flutter.dev');
  });

  group('EngineCachedArtifact', () {
    FakePlatform fakePlatform;
    MemoryFileSystem fileSystem;
    MockCache mockCache;
    MockOperatingSystemUtils mockOperatingSystemUtils;

    setUp(() {
      fakePlatform = FakePlatform(environment: const <String, String>{}, operatingSystem: 'linux');
      mockCache = MockCache();
      mockOperatingSystemUtils = MockOperatingSystemUtils();
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('makes binary dirs readable and executable by all', () async {
      final Directory artifactDir = fileSystem.systemTempDirectory.createTempSync('flutter_cache_test_artifact.');
      final Directory downloadDir = fileSystem.systemTempDirectory.createTempSync('flutter_cache_test_download.');
      when(mockCache.getArtifactDirectory(any)).thenReturn(artifactDir);
      when(mockCache.getDownloadDir()).thenReturn(downloadDir);
      artifactDir.childDirectory('bin_dir').createSync();
      artifactDir.childFile('unused_url_path').createSync();

      final FakeCachedArtifact artifact = FakeCachedArtifact(
        cache: mockCache,
        binaryDirs: <List<String>>[
          <String>['bin_dir', 'unused_url_path'],
        ],
        requiredArtifacts: DevelopmentArtifact.universal,
      );
      await artifact.updateInner(MockArtifactUpdater());
      final Directory dir = fileSystem.systemTempDirectory
          .listSync(recursive: true)
          .whereType<Directory>()
          .singleWhere((Directory directory) => directory.basename == 'bin_dir', orElse: () => null);
      expect(dir, isNotNull);
      expect(dir.path, artifactDir.childDirectory('bin_dir').path);
      verify(mockOperatingSystemUtils.chmod(argThat(hasPath(dir.path)), 'a+r,a+x'));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
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
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts(mockCache);
      expect(mavenArtifacts.developmentArtifact, DevelopmentArtifact.androidMaven);
    });

    testUsingContext('update', () async {
      final Directory cacheRoot = globals.fs.directory('/bin/cache')
        ..createSync(recursive: true);
      when(mockCache.getRoot()).thenReturn(cacheRoot);
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts(mockCache);
      expect(mavenArtifacts.isUpToDate(), isFalse);

      final Directory gradleWrapperDir = globals.fs.systemTempDirectory.createTempSync('flutter_cache_test_gradle_wrapper.');
      when(mockCache.getArtifactDirectory('gradle_wrapper')).thenReturn(gradleWrapperDir);

      globals.fs.directory(gradleWrapperDir.childDirectory('gradle').childDirectory('wrapper'))
          .createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(gradleWrapperDir.path, 'gradlew')).writeAsStringSync('irrelevant');
      globals.fs.file(globals.fs.path.join(gradleWrapperDir.path, 'gradlew.bat')).writeAsStringSync('irrelevant');

      when(globals.processManager.run(any, environment: captureAnyNamed('environment')))
        .thenAnswer((Invocation invocation) {
          final List<String> args = invocation.positionalArguments[0] as List<String>;
          expect(args.length, 6);
          expect(args[1], '-b');
          expect(args[2].endsWith('resolve_dependencies.gradle'), isTrue);
          expect(args[5], 'resolveDependencies');
          expect(invocation.namedArguments[#environment], gradleEnvironment);
          return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
        });

      await mavenArtifacts.update(MockArtifactUpdater());

      expect(mavenArtifacts.isUpToDate(), isFalse);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('macOS artifacts', () {
    MockCache mockCache;

    setUp(() {
      mockCache = MockCache();
    });

    testUsingContext('verifies executables for libimobiledevice in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('libimobiledevice', mockCache);
      when(mockCache.getArtifactDirectory(any)).thenReturn(globals.fs.currentDirectory);
      iosUsbArtifacts.location.createSync();
      final File ideviceScreenshotFile = iosUsbArtifacts.location.childFile('idevicescreenshot')
        ..createSync();
      iosUsbArtifacts.location.childFile('idevicesyslog')
        .createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);

      ideviceScreenshotFile.deleteSync();

      expect(iosUsbArtifacts.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('verifies iproxy for usbmuxd in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('usbmuxd', mockCache);
      when(mockCache.getArtifactDirectory(any)).thenReturn(globals.fs.currentDirectory);
      iosUsbArtifacts.location.createSync();
      final File iproxy = iosUsbArtifacts.location.childFile('iproxy')
        ..createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);

      iproxy.deleteSync();

      expect(iosUsbArtifacts.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does not verify executables for openssl in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('openssl', mockCache);
      when(mockCache.getArtifactDirectory(any)).thenReturn(globals.fs.currentDirectory);
      iosUsbArtifacts.location.createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('use unsigned when specified', () async {
      when(mockCache.useUnsignedMacBinaries).thenReturn(true);

      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('name', mockCache);
      expect(iosUsbArtifacts.archiveUri.toString(), contains('/unsigned/'));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
    });

    testUsingContext('not use unsigned when not specified', () async {
      when(mockCache.useUnsignedMacBinaries).thenReturn(false);

      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('name', mockCache);
      expect(iosUsbArtifacts.archiveUri.toString(), isNot(contains('/unsigned/')));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
    });
  });

  testWithoutContext('Downloads Flutter runner debug symbols', () async {
    final MockCache mockCache = MockCache();
    final MockVersionedPackageResolver mockPackageResolver = MockVersionedPackageResolver();
    final FlutterRunnerDebugSymbols flutterRunnerDebugSymbols = FlutterRunnerDebugSymbols(
      mockCache,
      packageResolver: mockPackageResolver,
      platform: FakePlatform(operatingSystem: 'linux'),
    );
    when(mockPackageResolver.resolveUrl(any, any)).thenReturn('');

    await flutterRunnerDebugSymbols.updateInner(MockArtifactUpdater());

    verifyInOrder(<void>[
      mockPackageResolver.resolveUrl('fuchsia-debug-symbols-x64', any),
      mockPackageResolver.resolveUrl('fuchsia-debug-symbols-arm64', any),
    ]);
  });

  testUsingContext('FontSubset in univeral artifacts', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    expect(artifacts.developmentArtifact, DevelopmentArtifact.universal);
  });

  testUsingContext('FontSubset artifacts on linux', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(false);
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['linux-x64', 'linux-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testUsingContext('FontSubset artifacts on windows', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(false);
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['windows-x64', 'windows-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'windows'),
  });

  testUsingContext('FontSubset artifacts on macos', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(false);
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['darwin-x64', 'darwin-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'macos'),
  });

  testUsingContext('FontSubset artifacts on fuchsia', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(false);
    expect(artifacts.getBinaryDirs, throwsToolExit(message: 'Unsupported operating system: ${globals.platform.operatingSystem}'));
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'fuchsia'),
  });

  testUsingContext('FontSubset artifacts for all platforms', () {
    final MockCache mockCache = MockCache();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(true);
    expect(artifacts.getBinaryDirs(), <List<String>>[
        <String>['darwin-x64', 'darwin-x64/font-subset.zip'],
        <String>['linux-x64', 'linux-x64/font-subset.zip'],
        <String>['windows-x64', 'windows-x64/font-subset.zip'],
    ]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'fuchsia'),
  });

  testUsingContext('macOS desktop artifacts ignore filtering when requested', () {
    final MockCache mockCache = MockCache();
    final MacOSEngineArtifacts artifacts = MacOSEngineArtifacts(mockCache);
    when(mockCache.includeAllPlatforms).thenReturn(false);
    when(mockCache.platformOverrideArtifacts).thenReturn(<String>{'macos'});

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testWithoutContext('Windows desktop artifacts ignore filtering when requested', () {
    final MockCache mockCache = MockCache();
    final WindowsEngineArtifacts artifacts = WindowsEngineArtifacts(
      mockCache,
      platform: FakePlatform(operatingSystem: 'linux'),
    );
    when(mockCache.includeAllPlatforms).thenReturn(false);
    when(mockCache.platformOverrideArtifacts).thenReturn(<String>{'windows'});

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  });

  testWithoutContext('Windows desktop artifacts include profile and release artifacts', () {
    final MockCache mockCache = MockCache();
    final WindowsEngineArtifacts artifacts = WindowsEngineArtifacts(
      mockCache,
      platform: FakePlatform(operatingSystem: 'windows'),
    );

    expect(artifacts.getBinaryDirs(), containsAll(<Matcher>[
      contains(contains('profile')),
      contains(contains('release')),
    ]));
  });

  testWithoutContext('Linux desktop artifacts ignore filtering when requested', () {
    final MockCache mockCache = MockCache();
    final LinuxEngineArtifacts artifacts = LinuxEngineArtifacts(
      mockCache,
      platform: FakePlatform(operatingSystem: 'macos'),
    );
    when(mockCache.includeAllPlatforms).thenReturn(false);
    when(mockCache.platformOverrideArtifacts).thenReturn(<String>{'linux'});

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  });

  testWithoutContext('Linux desktop artifacts include profile and release artifacts', () {
    final MockCache mockCache = MockCache();
    final LinuxEngineArtifacts artifacts = LinuxEngineArtifacts(
      mockCache,
      platform: FakePlatform(operatingSystem: 'linux'),
    );

    expect(artifacts.getBinaryDirs(), containsAll(<Matcher>[
      contains(contains('profile')),
      contains(contains('release')),
    ]));
  });

  testWithoutContext('Cache can delete stampfiles of artifacts', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );
    final File toolStampFile = fileSystem.file('bin/cache/flutter_tools.stamp');
    final File stampFile = cache.getStampFileFor(artifactSet.stampName);
    stampFile.createSync(recursive: true);
    toolStampFile.createSync(recursive: true);

    cache.clearStampFiles();

    expect(logger.errorText, isEmpty);
    expect(stampFile, isNot(exists));
    expect(toolStampFile, isNot(exists));
  });

   testWithoutContext('Cache does not attempt to delete already missing stamp files', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );
    final File toolStampFile = fileSystem.file('bin/cache/flutter_tools.stamp');
    final File stampFile = cache.getStampFileFor(artifactSet.stampName);
    toolStampFile.createSync(recursive: true);

    cache.clearStampFiles();

    expect(logger.errorText, isEmpty);
    expect(stampFile, isNot(exists));
    expect(toolStampFile, isNot(exists));
  });

  testWithoutContext('Cache catches file system exception from missing tool stamp file', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );

    cache.clearStampFiles();

    expect(logger.errorText, contains('Failed to delete some stamp files'));
  });

  testWithoutContext('Cache handles exception thrown if stamp file cannot be parsed', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Logger logger = BufferLogger.test();
    final FakeCache cache = FakeCache(
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils()
    );
    final MockFile file = MockFile();
    cache.stampFile = file;
    when(file.existsSync()).thenReturn(false);

    expect(cache.getStampFor('foo'), null);

    when(file.existsSync()).thenReturn(true);
    when(file.readAsStringSync()).thenThrow(const FileSystemException());

    expect(cache.getStampFor('foo'), null);

    when(file.existsSync()).thenReturn(true);
    when(file.readAsStringSync()).thenReturn('ABC ');

    expect(cache.getStampFor('foo'), 'ABC');
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

class FakeSimpleArtifact extends CachedArtifact {
  FakeSimpleArtifact(Cache cache) : super(
    'fake',
    cache,
    DevelopmentArtifact.universal,
  );

  @override
  Future<void> updateInner(ArtifactUpdater artifactUpdater) async {
    // nop.
  }
}

class FakeDownloadedArtifact extends CachedArtifact {
  FakeDownloadedArtifact(this.downloadedFile, Cache cache) : super(
    'fake',
    cache,
    DevelopmentArtifact.universal,
  );

  final File downloadedFile;

  @override
  Future<void> updateInner(ArtifactUpdater artifactUpdater) async {}
}

class MockArtifactUpdater extends Mock implements ArtifactUpdater {}
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
class MockVersionedPackageResolver extends Mock implements VersionedPackageResolver {}
class FakeCache extends Cache {
  FakeCache({
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    @required OperatingSystemUtils osUtils,
  }) : super(
    logger: logger,
    fileSystem: fileSystem,
    platform: platform,
    osUtils: osUtils,
    artifacts: <ArtifactSet>[],
  );

  File stampFile;

  @override
  File getStampFileFor(String artifactName) {
    return stampFile;
  }
}
