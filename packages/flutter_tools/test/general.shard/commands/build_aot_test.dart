// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/bitcode.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  MockXcode mockXcode;
  MemoryFileSystem memoryFileSystem;
  MockProcessManager mockProcessManager;
  MockPlistUtils mockPlistUtils;

  setUp(() {
    mockXcode = MockXcode();
    memoryFileSystem = MemoryFileSystem(style: FileSystemStyle.posix);
    mockProcessManager = MockProcessManager();
    mockPlistUtils = MockPlistUtils();
  });

  testUsingContext('build aot validates existence of Flutter.framework in engine', () async {
    await expectToolExitLater(
      validateBitcode(BuildMode.release, TargetPlatform.ios),
      equals('Flutter.framework not found at ios_profile/Flutter.framework'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('build aot prints error if Clang version invalid', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple pie version 10.1.0 (clang-4567.1.1.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await expectToolExitLater(
      validateBitcode(BuildMode.profile, TargetPlatform.ios),
      equals('Unable to parse Clang version from "Apple pie version 10.1.0 (clang-4567.1.1.1)". '
             'Expected a string like "Apple (LLVM|clang) #.#.# (clang-####.#.##.#)".'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });

  testUsingContext('build aot can parse valid Xcode Clang version (10)', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 10.1.0 (clang-4567.1.1.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode(BuildMode.profile, TargetPlatform.ios);

  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });

  testUsingContext('build aot can parse valid Xcode Clang version (11)', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple clang version 11.0.0 (clang-4567.1.1.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode(BuildMode.profile, TargetPlatform.ios);
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });

  testUsingContext('build aot validates Flutter.framework/Flutter was built with same toolchain', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 10.0.0 (clang-4567.1.1.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await expectToolExitLater(
      validateBitcode(BuildMode.release, TargetPlatform.ios),
      equals('The Flutter.framework at ios_profile/Flutter.framework was built with "Apple LLVM version 10.0.1 '
             '(clang-1234.1.12.1)", but the current version of clang is "Apple LLVM version 10.0.0 (clang-4567.1.1.1)". '
             'This will result in failures when trying to archive an IPA. To resolve this issue, update your version '
             'of Xcode to at least 10.0.1.'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });

  testUsingContext('build aot validates and succeeds - same version of Xcode', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 10.0.1 (clang-1234.1.12.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode(BuildMode.release, TargetPlatform.ios);

    expect(testLogger.statusText, '');
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });

  testUsingContext('build aot validates and succeeds when user has newer version of Xcode', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 11.0.1 (clang-1234.1.12.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockPlistUtils.getValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode(BuildMode.release, TargetPlatform.ios);

    expect(testLogger.statusText, '');
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('ios_profile', 'host_profile',
      fileSystem: memoryFileSystem,
      cache: globals.cache,
      platform: globals.platform,
      processManager: mockProcessManager,
    ),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    PlistParser: () => mockPlistUtils,
  });
}

class MockXcode extends Mock implements Xcode {}
class MockPlistUtils extends Mock implements PlistParser {}
