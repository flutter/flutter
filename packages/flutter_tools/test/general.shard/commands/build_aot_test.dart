// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/build_aot.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  MockXcode mockXcode;
  MemoryFileSystem memoryFileSystem;
  MockProcessManager mockProcessManager;
  BufferLogger bufferLogger;
  MockIOSWorkflow mockIOSWorkflow;

  setUp(() {
    mockXcode = MockXcode();
    memoryFileSystem = MemoryFileSystem(style: FileSystemStyle.posix);
    mockProcessManager = MockProcessManager();
    bufferLogger = BufferLogger();
    mockIOSWorkflow = MockIOSWorkflow();
  });

  testUsingContext('build aot validates building with bitcode requires a local engine', () async {
    await expectToolExitLater(
      validateBitcode(),
      equals('Bitcode is only supported with a local engine built with --bitcode.'),
    );
  });

  testUsingContext('build aot validates existence of Flutter.framework in engine', () async {
    await expectToolExitLater(
      validateBitcode(),
      equals('Flutter.framework not found at ios_profile/Flutter.framework'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('/engine', 'ios_profile', 'host_profile'),
    FileSystem: () => memoryFileSystem,
  });

  testUsingContext('build aot validates Flutter.framework/Flutter contains bitcode', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    flutterFramework.childFile('Info.plist').createSync();

    final RunResult otoolResult = RunResult(
      FakeProcessResult(stdout: '', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.otool(any)).thenAnswer((_) => Future<RunResult>.value(otoolResult));
    await expectToolExitLater(
      validateBitcode(),
      equals('The Flutter.framework at ios_profile/Flutter.framework does not contain bitcode.'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('/engine', 'ios_profile', 'host_profile'),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
  });

  testUsingContext('build aot validates Flutter.framework/Flutter was built with same toolchain', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult otoolResult = RunResult(
      FakeProcessResult(stdout: '__LLVM', stderr: ''),
      const <String>['foo'],
    );
    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 10.0.0 (clang-4567.1.1.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.otool(any)).thenAnswer((_) => Future<RunResult>.value(otoolResult));
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockIOSWorkflow.getPlistValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await expectToolExitLater(
      validateBitcode(),
      equals('The Flutter.framework at ios_profile/Flutter.framework was built with "Apple LLVM version 10.0.1 '
             '(clang-1234.1.12.1)", but the current version of clang is "Apple LLVM version 10.0.0 (clang-4567.1.1.1)". '
             'This will result in failures when trying toarchive an IPA. To resolve this issue, update your version '
             'of Xcode to at least 10.0.1.'),
    );
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('/engine', 'ios_profile', 'host_profile'),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    Logger: () => bufferLogger,
    IOSWorkflow: () => mockIOSWorkflow,
  });

  testUsingContext('build aot validates and succeeds - same version of Xcode', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult otoolResult = RunResult(
      FakeProcessResult(stdout: '__LLVM', stderr: ''),
      const <String>['foo'],
    );
    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 10.0.1 (clang-1234.1.12.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.otool(any)).thenAnswer((_) => Future<RunResult>.value(otoolResult));
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockIOSWorkflow.getPlistValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode();

    expect(bufferLogger.statusText, '');
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('/engine', 'ios_profile', 'host_profile'),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    Logger: () => bufferLogger,
    IOSWorkflow: () => mockIOSWorkflow,
  });

  testUsingContext('build aot validates and succeeds when user has newer version of Xcode', () async {
    final Directory flutterFramework = memoryFileSystem.directory('ios_profile/Flutter.framework')
      ..createSync(recursive: true);
    flutterFramework.childFile('Flutter').createSync();
    final File infoPlist = flutterFramework.childFile('Info.plist')..createSync();

    final RunResult otoolResult = RunResult(
      FakeProcessResult(stdout: '__LLVM', stderr: ''),
      const <String>['foo'],
    );
    final RunResult clangResult = RunResult(
      FakeProcessResult(stdout: 'Apple LLVM version 11.0.1 (clang-1234.1.12.1)\nBlahBlah\n', stderr: ''),
      const <String>['foo'],
    );
    when(mockXcode.otool(any)).thenAnswer((_) => Future<RunResult>.value(otoolResult));
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(clangResult));
    when(mockIOSWorkflow.getPlistValueFromFile(infoPlist.path, 'ClangVersion')).thenReturn('Apple LLVM version 10.0.1 (clang-1234.1.12.1)');

    await validateBitcode();

    expect(bufferLogger.statusText, '');
  }, overrides: <Type, Generator>{
    Artifacts: () => LocalEngineArtifacts('/engine', 'ios_profile', 'host_profile'),
    FileSystem: () => memoryFileSystem,
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
    Logger: () => bufferLogger,
    IOSWorkflow: () => mockIOSWorkflow,
  });
}

class MockXcode extends Mock implements Xcode {}
class MockIOSWorkflow extends Mock implements IOSWorkflow {}
