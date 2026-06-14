// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

      expect(cCompilerConfigLinux(cmakeDirectory: environment.buildDir), throwsA(isA<ToolExit>()));
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

      expect(cCompilerConfigLinux(cmakeDirectory: environment.buildDir), throwsA(isA<ToolExit>()));
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
}

class _BuildRunnerWithoutClang extends FakeFlutterNativeAssetsBuildRunner {}
