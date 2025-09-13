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
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.create(recursive: true);

      await runFlutterSpecificHooks(
        environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: _BuildRunnerWithoutClang(),
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
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <Pattern>['which', 'clang++'],
          stdout: '''
/some/path/to/clang++
''', // Newline at the end of the string.
        ),
      ]),
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

      final CCompilerConfig result = await cCompilerConfigLinux();
      expect(result.compiler, Uri.file('/some/path/to/clang'));
    },
  );

  const kDependentExecutables = <String>['ld.lld', 'llvm-ar', 'clang'];
  testUsingContext(
    'cCompilerConfigLinux when executables are not installed alongside clang++',
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <Pattern>['which', 'clang++'], stdout: '/path/to/clang++'),
        for (final String executableName in kDependentExecutables) ...[
          FakeCommand(
            command: <Pattern>['which', executableName],
            stdout: '/different/path/to/$executableName',
          ),
        ],
      ]),
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      await fileSystem.file('/path/to/clang++').create(recursive: true);
      for (final executableName in kDependentExecutables) {
        await fileSystem.file('/different/path/to/$executableName').create(recursive: true);
      }

      final CCompilerConfig result = await cCompilerConfigLinux();
      expect(result.linker, Uri.file('/different/path/to/ld.lld'));
      expect(result.archiver, Uri.file('/different/path/to/llvm-ar'));
      expect(result.compiler, Uri.file('/different/path/to/clang'));
    },
  );

  const kAllExecutables = <String>['clang++', 'ld.lld', 'llvm-ar', 'clang'];
  testUsingContext(
    'cCompilerConfigLinux when no executables are found on PATH',
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        for (final String executableName in kAllExecutables) ...[
          FakeCommand(command: <Pattern>['which', executableName], exitCode: 1),
        ],
      ]),
    },
    () async {
      if (!const LocalPlatform().isLinux) {
        return;
      }

      expect(cCompilerConfigLinux(), throwsA(isA<ToolExit>()));
    },
  );
}

class _BuildRunnerWithoutClang extends FakeFlutterNativeAssetsBuildRunner {}
