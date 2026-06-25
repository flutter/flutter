// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/linux/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../fake_native_assets_build_runner.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment environment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Uri projectUri;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    projectUri = environment.projectDir.uri;
  });

  testUsingContext(
    'does not throw if clang not present but no native assets present',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.create(recursive: true);

      await runFlutterSpecificHooks(
        environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: _BuildRunnerWithoutClang(),
        buildCodeAssets: BuildCodeAssetsOptions(appBuildDirectory: environment.outputDir),
        buildDataAssets: true,
      );
      expect(
        (globals.logger as BufferLogger).traceText,
        isNot(contains('Building native assets for ')),
      );
    },
  );

  // This logic is mocked in the other tests to avoid having test order
  // randomization causing issues with what processes are invoked.
  // Exercise the parsing of the process output in this separate test.
  testUsingContext(
    'cCompilerConfigLinux',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await fileSystem.directory('/some/path/to/').create(recursive: true);
      await fileSystem.file('/some/path/to/clang++').create();
      await fileSystem.file('/some/path/to/clang').create();
      await fileSystem.file('/some/path/to/llvm-ar').create();
      await fileSystem.file('/some/path/to/ld.lld').create();

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
//CXX compiler
CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++

//LLVM archiver
CMAKE_AR:FILEPATH=/some/path/to/llvm-ar

CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      final CCompilerConfig result = (await cCompilerConfigLinux(
        cmakeDirectory: environment.outputDir,
      ))!;
      expect(result.compiler, Uri.file('/some/path/to/clang'));
      expect(result.archiver, Uri.file('/some/path/to/llvm-ar'));
      expect(result.linker, Uri.file('/some/path/to/ld.lld'));
    },
  );

  testUsingContext(
    'cCompilerConfigLinux gcc linker',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await fileSystem.directory('/some/path/to/').create(recursive: true);
      await fileSystem.file('/some/path/to/clang++').create();
      await fileSystem.file('/some/path/to/clang').create();
      await fileSystem.directory('/usr/bin/').create(recursive: true);
      await fileSystem.file('/usr/bin/ar').create();
      await fileSystem.file('/usr/bin/ld').create();

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
//CXX compiler
CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++

//LLVM archiver
CMAKE_AR:FILEPATH=/usr/bin/ar

CMAKE_LINKER:FILEPATH=/usr/bin/ld
''');

      final CCompilerConfig result = (await cCompilerConfigLinux(
        cmakeDirectory: environment.outputDir,
      ))!;
      expect(result.compiler, Uri.file('/some/path/to/clang'));
      expect(result.archiver, Uri.file('/usr/bin/ar'));
      expect(result.linker, Uri.file('/usr/bin/ld'));
    },
  );

  testUsingContext(
    'cCompilerConfigLinux missing CMakeCache',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      expect(cCompilerConfigLinux(cmakeDirectory: environment.buildDir), throwsA(isA<ToolExit>()));
    },
  );

  testUsingContext(
    'cCompilerConfigLinux missing entry',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
//CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++
//CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
# CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      expect(cCompilerConfigLinux(cmakeDirectory: environment.outputDir), throwsA(isA<ToolExit>()));
    },
  );

  testUsingContext(
    'cCompilerConfigLinux invalid paths',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++
CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      expect(cCompilerConfigLinux(cmakeDirectory: environment.outputDir), throwsA(isA<ToolExit>()));
    },
  );

  testUsingContext(
    'cCompilerConfigLinux with missing binaries when not required',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await fileSystem.file('/a/path/to/clang++').create(recursive: true);
      expect(cCompilerConfigLinux(), completes);
    },
  );

  testUsingContext(
    'cCompilerConfigLinux missing CMakeCache and throwIfNotFound: false',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      final CCompilerConfig? result = await cCompilerConfigLinux(
        cmakeDirectory: environment.buildDir,
        throwIfNotFound: false,
      );
      expect(result, isNull);
    },
  );

  testUsingContext(
    'cCompilerConfigLinux missing entry and throwIfNotFound: false',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
//CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++
//CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
# CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      final CCompilerConfig? result = await cCompilerConfigLinux(
        cmakeDirectory: environment.outputDir,
        throwIfNotFound: false,
      );
      expect(result, isNull);
    },
  );

  testUsingContext(
    'cCompilerConfigLinux invalid paths and throwIfNotFound: false',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=/some/path/to/clang++
CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      final CCompilerConfig? result = await cCompilerConfigLinux(
        cmakeDirectory: environment.outputDir,
        throwIfNotFound: false,
      );
      expect(result, isNull);
    },
  );

  testUsingContext(
    'cCompilerConfigLinux FileSystemException on resolveSymbolicLinks and throwIfNotFound: false',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => _ThrowingResolveFileSystem(
            fileSystem,
            '${environment.outputDir.path}/mock_clang++',
          ),
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=${environment.outputDir.path}/mock_clang++
CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      // Create the file so requireTool passes existsSync()
      await environment.outputDir.childFile('mock_clang++').create();

      final CCompilerConfig? result = await cCompilerConfigLinux(
        cmakeDirectory: environment.outputDir,
        throwIfNotFound: false,
      );
      expect(result, isNull);
    },
  );

  testUsingContext(
    'cCompilerConfigLinux FileSystemException on resolveSymbolicLinks and throwIfNotFound: true',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => _ThrowingResolveFileSystem(
            fileSystem,
            '${environment.outputDir.path}/mock_clang++',
          ),
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await environment.outputDir.childFile('CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=${environment.outputDir.path}/mock_clang++
CMAKE_AR:FILEPATH=/some/path/to/llvm-ar
CMAKE_LINKER:FILEPATH=/some/path/to/ld.lld
''');

      // Create the file so requireTool passes existsSync()
      await environment.outputDir.childFile('mock_clang++').create();

      expect(
        cCompilerConfigLinux(cmakeDirectory: environment.outputDir),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}

class _BuildRunnerWithoutClang extends FakeFlutterNativeAssetsBuildRunner {}

class _ThrowingResolveFileSystem extends ForwardingFileSystem {
  _ThrowingResolveFileSystem(super.delegate, this.throwingPath);

  final String throwingPath;

  @override
  File file(dynamic path) {
    final File delegateFile = super.file(path);
    if (delegateFile.path == throwingPath) {
      return _ThrowingResolveFile(this, delegateFile);
    }
    return delegateFile;
  }
}

class _ThrowingResolveFile extends ForwardingFileSystemEntity<File, io.File> with ForwardingFile {
  _ThrowingResolveFile(this.fileSystem, this.delegate);

  @override
  final io.File delegate;

  @override
  final FileSystem fileSystem;

  @override
  File wrapFile(io.File delegate) => _ThrowingResolveFile(fileSystem, delegate);

  @override
  Directory wrapDirectory(io.Directory delegate) => throw UnimplementedError();

  @override
  Link wrapLink(io.Link delegate) => throw UnimplementedError();

  @override
  Future<String> resolveSymbolicLinks() async {
    throw const FileSystemException('Mock FileSystemException during resolveSymbolicLinks');
  }

  @override
  String resolveSymbolicLinksSync() {
    throw const FileSystemException('Mock FileSystemException during resolveSymbolicLinksSync');
  }
}
