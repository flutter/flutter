// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart' hide FakeProcess;

void main() {
  testWithoutContext('StdoutHandler can produce output message', () async {
    final stdoutHandler = StdoutHandler(
      logger: BufferLogger.test(),
      fileSystem: MemoryFileSystem.test(),
    );
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 0');
    final CompilerOutput? output = await stdoutHandler.compilerOutput?.future;
    expect(output?.errorCount, 0);
    expect(output?.outputFilename, 'message');
    expect(output?.expressionData, null);
  });

  testWithoutContext('StdoutHandler can read output bytes', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final stdoutHandler = StdoutHandler(logger: BufferLogger.test(), fileSystem: fileSystem);
    fileSystem.file('message').writeAsBytesSync(<int>[1, 2, 3, 4]);

    stdoutHandler.reset(readFile: true);
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 0');
    final CompilerOutput? output = await stdoutHandler.compilerOutput?.future;

    expect(output?.errorCount, 0);
    expect(output?.outputFilename, 'message');
    expect(output?.expressionData, <int>[1, 2, 3, 4]);
  });

  testWithoutContext('StdoutHandler reads output bytes if errorCount > 0', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final stdoutHandler = StdoutHandler(logger: BufferLogger.test(), fileSystem: fileSystem);
    fileSystem.file('message').writeAsBytesSync(<int>[1, 2, 3, 4]);

    stdoutHandler.reset(readFile: true);
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 1');
    final CompilerOutput? output = await stdoutHandler.compilerOutput?.future;

    expect(output?.errorCount, 1);
    expect(output?.outputFilename, 'message');
    expect(output?.expressionData, <int>[1, 2, 3, 4]);
  });

  testWithoutContext('TargetModel values', () {
    expect(TargetModel('vm'), TargetModel.vm);
    expect(TargetModel.vm.toString(), 'vm');

    expect(TargetModel('flutter'), TargetModel.flutter);
    expect(TargetModel.flutter.toString(), 'flutter');

    expect(TargetModel('flutter_runner'), TargetModel.flutterRunner);
    expect(TargetModel.flutterRunner.toString(), 'flutter_runner');

    expect(TargetModel('dartdevc'), TargetModel.dartdevc);
    expect(TargetModel.dartdevc.toString(), 'dartdevc');

    expect(() => TargetModel('foobar'), throwsException);
  });

  testWithoutContext('toMultiRootPath maps different URIs', () async {
    expect(
      toMultiRootPath(Uri.parse('file:///a/b/c'), 'scheme', <String>['/a/b'], false),
      'scheme:///c',
    );
    expect(
      toMultiRootPath(Uri.parse('file:///d/b/c'), 'scheme', <String>['/a/b'], false),
      'file:///d/b/c',
    );
    expect(
      toMultiRootPath(Uri.parse('file:///a/b/c'), 'scheme', <String>['/d/b', '/a/b'], false),
      'scheme:///c',
    );
    expect(toMultiRootPath(Uri.parse('file:///a/b/c'), null, <String>[], false), 'file:///a/b/c');
    expect(
      toMultiRootPath(Uri.parse('org-dartlang-app:///a/b/c'), null, <String>[], false),
      'org-dartlang-app:///a/b/c',
    );
    expect(
      toMultiRootPath(Uri.parse('org-dartlang-app:///a/b/c'), 'scheme', <String>['/d/b'], false),
      'org-dartlang-app:///a/b/c',
    );
  });

  testWithoutContext('buildModeOptions removes matching product define', () {
    expect(buildModeOptions(BuildMode.debug, <String>['dart.vm.product=true']), <String>[
      '-Ddart.vm.profile=false',
      '--enable-asserts',
    ]);
  });

  testWithoutContext('buildModeOptions removes matching profile define in debug mode', () {
    expect(buildModeOptions(BuildMode.debug, <String>['dart.vm.profile=true']), <String>[
      '-Ddart.vm.product=false',
      '--enable-asserts',
    ]);
  });

  testWithoutContext(
    'buildModeOptions removes both matching profile and release define in debug mode',
    () {
      expect(
        buildModeOptions(BuildMode.debug, <String>['dart.vm.profile=true', 'dart.vm.product=true']),
        <String>['--enable-asserts'],
      );
    },
  );

  testWithoutContext('buildModeOptions removes matching profile define in profile mode', () {
    expect(buildModeOptions(BuildMode.profile, <String>['dart.vm.profile=true']), <String>[
      '-Ddart.vm.product=false',
      '--delete-tostring-package-uri=dart:ui',
      '--delete-tostring-package-uri=package:flutter',
    ]);
  });

  testWithoutContext(
    'buildModeOptions removes both matching profile and release define in profile mode',
    () {
      expect(
        buildModeOptions(BuildMode.profile, <String>[
          'dart.vm.profile=false',
          'dart.vm.product=true',
        ]),
        <String>[
          '--delete-tostring-package-uri=dart:ui',
          '--delete-tostring-package-uri=package:flutter',
        ],
      );
    },
  );

  testWithoutContext(
    'includeUnsupportedPlatformLibraryStubs is only valid for Target.dartdevc',
    () {
      final unsupportedTargetModels = <TargetModel>{
        TargetModel.flutter,
        TargetModel.flutterRunner,
        TargetModel.vm,
      };

      // Initializing the compiler with includeUnsupportedPlatformLibraryStubs for targets other
      // than DDC is not currently supported as it's limited for use with the widget previewer.
      for (final target in unsupportedTargetModels) {
        try {
          ResidentCompiler(
            'sdkroot',
            buildMode: BuildMode.debug,
            logger: BufferLogger.test(),
            processManager: FakeProcessManager.any(),
            artifacts: Artifacts.test(),
            platform: FakePlatform(),
            fileSystem: MemoryFileSystem.test(),
            shutdownHooks: FakeShutdownHooks(),
            targetModel: target,
            includeUnsupportedPlatformLibraryStubs: true,
          );
          fail('Unsupported target did not throw.');
        } on StateError catch (e) {
          expect(
            e.message,
            'includeUnsupportedPlatformLibraryStubs should only be used by the widget-preview '
            'command.',
          );
        }
      }

      // Initializing the compiler with includeUnsupportedPlatformLibraryStubs for DDC is
      // supported.
      ResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        artifacts: Artifacts.test(),
        platform: FakePlatform(),
        fileSystem: MemoryFileSystem.test(),
        shutdownHooks: FakeShutdownHooks(),
        targetModel: TargetModel.dartdevc,
        includeUnsupportedPlatformLibraryStubs: true,
      );
    },
  );

  testWithoutContext(
    'Strips --include-unsupported-platform-library-stubs from extraFrontEndOptions',
    () async {
      final completer = Completer<void>();
      final processManager = FakeProcessManager.list([
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime.TargetPlatform.web_javascript',
            'Artifact.frontendServerSnapshotForEngineDartSdk.TargetPlatform.web_javascript',
            '--sdk-root',
            'sdkroot/',
            '--incremental',
            '--target=dartdevc',
            '--experimental-emit-debug-metadata',
            '--output-dill',
            'foo.dill',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--track-widget-creation',
            '--verbosity=error',
            '--extra-flag',
          ],
          onRun: (_) => completer.complete(),
        ),
      ]);
      final compiler = DefaultResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: BufferLogger.test(),
        processManager: processManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(),
        fileSystem: MemoryFileSystem.test(),
        shutdownHooks: FakeShutdownHooks(),
        targetModel: TargetModel.dartdevc,
        // Don't explicitly enable includeUnsupportedPlatformLibraryStubs to ensure it's not
        // included in the argument list.
        // ignore: avoid_redundant_argument_values
        includeUnsupportedPlatformLibraryStubs: false,
        extraFrontEndOptions: [
          '--include-unsupported-platform-library-stubs',
          // Include a random extra flag to ensure not all extra options are stripped.
          '--extra-flag',
        ],
      );

      await runZonedGuarded(
        () {
          // This throws ToolExit as the FakeProcess immediately closes stdout and stderr.
          compiler.recompile(
            Uri.file('foo.dart'),
            [],
            outputPath: 'foo.dill',
            packageConfig: PackageConfig.empty,
          );
        },
        (e, st) {
          if (e is! ToolExit) {
            completer.completeError(e, st);
          }
        },
      );

      // Fail if the command isn't run. This can happen when the commands actual arguments don't
      // match.
      await completer.future.timeout(const Duration(seconds: 5));
    },
  );

  testWithoutContext(
    '--include-unsupported-platform-library-stubs when includeUnsupportedPlatformLibraryStubs is set',
    () async {
      final completer = Completer<void>();
      final processManager = FakeProcessManager.list([
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime.TargetPlatform.web_javascript',
            'Artifact.frontendServerSnapshotForEngineDartSdk.TargetPlatform.web_javascript',
            '--sdk-root',
            'sdkroot/',
            '--incremental',
            '--target=dartdevc',
            '--experimental-emit-debug-metadata',
            '--output-dill',
            'foo.dill',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--track-widget-creation',
            '--include-unsupported-platform-library-stubs',
            '--verbosity=error',
            '--extra-flag',
          ],
          onRun: (_) => completer.complete(),
        ),
      ]);
      final compiler = DefaultResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: BufferLogger.test(),
        processManager: processManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(),
        fileSystem: MemoryFileSystem.test(),
        shutdownHooks: FakeShutdownHooks(),
        targetModel: TargetModel.dartdevc,
        // Explicitly enable includeUnsupportedPlatformLibraryStubs to ensure it's included in the
        // argument list.
        includeUnsupportedPlatformLibraryStubs: true,
        extraFrontEndOptions: [
          // Include a random extra flag to ensure not all extra options are stripped.
          '--extra-flag',
        ],
      );

      await runZonedGuarded(
        () {
          // This throws ToolExit as the FakeProcess immediately closes stdout and stderr.
          compiler.recompile(
            Uri.file('foo.dart'),
            [],
            outputPath: 'foo.dill',
            packageConfig: PackageConfig.empty,
          );
        },
        (e, st) {
          if (e is! ToolExit) {
            completer.completeError(e, st);
          }
        },
      );

      // Fail if the command isn't run. This can happen when the commands actual arguments don't
      // match.
      await completer.future.timeout(const Duration(seconds: 5));
    },
  );
}
