// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/async_guard.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

void main() {
  ResidentCompiler generator;
  ResidentCompiler generatorWithScheme;
  MemoryIOSink frontendServerStdIn;
  BufferLogger testLogger;

  setUp(() {
    testLogger = BufferLogger.test();
    frontendServerStdIn = MemoryIOSink();
  });

  // Migrated to not use mocks.
  group('fake process manager', () {
    FakeProcessManager fakeProcessManager;

    const List<String> frontendServerCommand = <String>[
      'Artifact.engineDartBinary',
      '--disable-dart-dev',
      'Artifact.frontendServerSnapshotForEngineDartSdk',
      '--sdk-root',
      'sdkroot/',
      '--incremental',
      '--target=flutter',
      '--debugger-module-names',
      '--experimental-emit-debug-metadata',
      '--output-dill',
      '/build/',
      '-Ddart.vm.profile=false',
      '-Ddart.vm.product=false',
      '--enable-asserts',
      '--track-widget-creation',
    ];

    setUp(() {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
      generator = ResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: testLogger,
        processManager: fakeProcessManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        fileSystem: MemoryFileSystem.test(),
      );
      generatorWithScheme = ResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: testLogger,
        processManager: fakeProcessManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        fileSystemRoots: <String>[
          '/foo/bar/fizz',
        ],
        fileSystemScheme: 'scheme',
        fileSystem: MemoryFileSystem.test(),
      );
    });

    testWithoutContext('incremental compile single dart compile', () async {
      fakeProcessManager.addCommand(FakeCommand(
        command: frontendServerCommand,
        stdout: 'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0',
        stdin: frontendServerStdIn,
      ));

      final CompilerOutput output = await generator.recompile(
        Uri.parse('/path/to/main.dart'),
          null /* invalidatedFiles */,
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');
      expect(testLogger.errorText, equals('line1\nline2\n'));
      expect(output.outputFilename, equals('/path/to/main.dart.dill'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('incremental compile single dart compile with filesystem scheme', () async {
      fakeProcessManager.addCommand(FakeCommand(
        command: const <String>[
          ...frontendServerCommand,
          '--filesystem-root',
          '/foo/bar/fizz',
          '--filesystem-scheme',
          'scheme',
        ],
        stdout: 'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0',
        stdin: frontendServerStdIn,
      ));

      final CompilerOutput output = await generatorWithScheme.recompile(
        Uri.parse('file:///foo/bar/fizz/main.dart'),
          null /* invalidatedFiles */,
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');
      expect(testLogger.errorText, equals('line1\nline2\n'));
      expect(output.outputFilename, equals('/path/to/main.dart.dill'));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('incremental compile single dart compile abnormally terminates', () async {
      fakeProcessManager.addCommand(FakeCommand(
        command: frontendServerCommand,
        stdin: frontendServerStdIn,
      ));

      expect(asyncGuard(() => generator.recompile(
        Uri.parse('/path/to/main.dart'),
        null, /* invalidatedFiles */
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      )), throwsToolExit());
    });

    testWithoutContext('incremental compile single dart compile abnormally terminates via exitCode', () async {
      fakeProcessManager.addCommand(FakeCommand(
        command: frontendServerCommand,
        stdin: frontendServerStdIn,
        exitCode: 1,
      ));

      expect(asyncGuard(() => generator.recompile(
        Uri.parse('/path/to/main.dart'),
        null, /* invalidatedFiles */
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      )), throwsToolExit(message: 'the Dart compiler exited unexpectedly.'));
    });
  });

  // Using mocks with stdout streaming.
  group('mock process manager', () {
    ProcessManager mockProcessManager;
    MockProcess mockFrontendServer;
    StreamController<String> stdErrStreamController;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockFrontendServer = MockProcess();

      stdErrStreamController = StreamController<String>();
      when(mockFrontendServer.stdin).thenReturn(frontendServerStdIn);
      when(mockFrontendServer.stderr)
          .thenAnswer((Invocation invocation) => stdErrStreamController.stream.transform(utf8.encoder));
      when(mockFrontendServer.exitCode).thenAnswer((Invocation invocation) {
        return Completer<int>().future;
      });

      when(mockProcessManager.canRun(any)).thenReturn(true);
      when(mockProcessManager.start(any)).thenAnswer(
              (Invocation invocation) => Future<Process>.value(mockFrontendServer)
      );
      generator = ResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: testLogger,
        processManager: mockProcessManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        fileSystem: MemoryFileSystem.test(),
      );
      generatorWithScheme = ResidentCompiler(
        'sdkroot',
        buildMode: BuildMode.debug,
        logger: testLogger,
        processManager: mockProcessManager,
        artifacts: Artifacts.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        fileSystemRoots: <String>[
          '/foo/bar/fizz',
        ],
        fileSystemScheme: 'scheme',
        fileSystem: MemoryFileSystem.test(),
      );
    });

    testWithoutContext('incremental compile and recompile', () async {
      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));
      await generator.recompile(
        Uri.parse('/path/to/main.dart'),
        null, /* invalidatedFiles */
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      // No accept or reject commands should be issued until we
      // send recompile request.
      await _accept(streamController, generator, frontendServerStdIn, '');
      await _reject(streamController, generator, frontendServerStdIn, '', '');

      await _recompile(streamController, generator, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

      await _accept(streamController, generator, frontendServerStdIn, r'^accept\n$');

      await _recompile(streamController, generator, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
      // No sources returned from reject command.
      await _reject(streamController, generator, frontendServerStdIn, 'result abc\nabc\n',
        r'^reject\n$');
      expect(frontendServerStdIn.getAndClear(), isEmpty);
      expect(testLogger.errorText, equals(
        'line0\nline1\n'
        'line1\nline2\n'
        'line1\nline2\n'
      ));
    });

    testWithoutContext('incremental compile and recompile with filesystem scheme', () async {
      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));
      await generatorWithScheme.recompile(
        Uri.parse('file:///foo/bar/fizz/main.dart'),
        null, /* invalidatedFiles */
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');

      // No accept or reject commands should be issued until we
      // send recompile request.
      await _accept(streamController, generatorWithScheme, frontendServerStdIn, '');
      await _reject(streamController, generatorWithScheme, frontendServerStdIn, '', '');

      await _recompile(streamController, generatorWithScheme, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
        mainUri: Uri.parse('file:///foo/bar/fizz/main.dart'),
        expectedMainUri: 'scheme:///main.dart');

      await _accept(streamController, generatorWithScheme, frontendServerStdIn, r'^accept\n$');

      await _recompile(streamController, generatorWithScheme, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
        mainUri: Uri.parse('file:///foo/bar/fizz/main.dart'),
        expectedMainUri: 'scheme:///main.dart');
      // No sources returned from reject command.
      await _reject(streamController, generatorWithScheme, frontendServerStdIn, 'result abc\nabc\n',
        r'^reject\n$');
      expect(frontendServerStdIn.getAndClear(), isEmpty);
      expect(testLogger.errorText, equals(
        'line0\nline1\n'
        'line1\nline2\n'
        'line1\nline2\n'
      ));
    });

    testWithoutContext('incremental compile and recompile non-entrypoint file with filesystem scheme', () async {
      final Uri mainUri = Uri.parse('file:///foo/bar/fizz/main.dart');
      const String expectedMainUri = 'scheme:///main.dart';
      final List<Uri> updatedUris = <Uri>[
        mainUri,
        Uri.parse('file:///foo/bar/fizz/other.dart'),
      ];
      const List<String> expectedUpdatedUris = <String>[
        expectedMainUri,
        'scheme:///other.dart',
      ];

      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));
      await generatorWithScheme.recompile(
        Uri.parse('file:///foo/bar/fizz/main.dart'),
        null, /* invalidatedFiles */
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');

      // No accept or reject commands should be issued until we
      // send recompile request.
      await _accept(streamController, generatorWithScheme, frontendServerStdIn, '');
      await _reject(streamController, generatorWithScheme, frontendServerStdIn, '', '');

      await _recompile(streamController, generatorWithScheme, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
        mainUri: mainUri,
        expectedMainUri: expectedMainUri,
        updatedUris: updatedUris,
        expectedUpdatedUris: expectedUpdatedUris);

      await _accept(streamController, generatorWithScheme, frontendServerStdIn, r'^accept\n$');

      await _recompile(streamController, generatorWithScheme, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
        mainUri: mainUri,
        expectedMainUri: expectedMainUri,
        updatedUris: updatedUris,
        expectedUpdatedUris: expectedUpdatedUris);
      // No sources returned from reject command.
      await _reject(streamController, generatorWithScheme, frontendServerStdIn, 'result abc\nabc\n',
        r'^reject\n$');
      expect(frontendServerStdIn.getAndClear(), isEmpty);
      expect(testLogger.errorText, equals(
        'line0\nline1\n'
        'line1\nline2\n'
        'line1\nline2\n'
      ));
    });

    testWithoutContext('incremental compile can suppress errors', () async {
      final StreamController<List<int>> stdoutController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => stdoutController.stream);

      stdoutController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));

      await generator.recompile(
        Uri.parse('/path/to/main.dart'),
        <Uri>[],
        outputPath: '/build/',
        packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(stdoutController, generator, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

      await _accept(stdoutController, generator, frontendServerStdIn, r'^accept\n$');

      await _recompile(stdoutController, generator, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n', suppressErrors: true);

      expect(frontendServerStdIn.getAndClear(), isEmpty);

      // Compiler message is not printed with suppressErrors: true above.
      expect(testLogger.errorText, isNot(equals(
        'line1\nline2\n'
      )));
      expect(testLogger.traceText, contains(
        'line1\nline2\n'
      ));
    });

    testWithoutContext('incremental compile and recompile twice', () async {
      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode(
        'result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'
      ));
      await generator.recompile(
        Uri.parse('/path/to/main.dart'),
        null /* invalidatedFiles */,
        outputPath: '/build/',
         packageConfig: PackageConfig.empty,
      );
      expect(frontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, frontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
      await _recompile(streamController, generator, frontendServerStdIn,
        'result abc\nline2\nline3\nabc\nabc /path/to/main.dart.dill 0\n');

      expect(frontendServerStdIn.getAndClear(), isEmpty);
      expect(testLogger.errorText, equals(
        'line0\nline1\n'
        'line1\nline2\n'
        'line2\nline3\n'
      ));
    });
  });
}

Future<void> _recompile(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MemoryIOSink frontendServerStdIn,
  String mockCompilerOutput, {
  bool suppressErrors = false,
  Uri mainUri,
  String expectedMainUri = '/path/to/main.dart',
  List<Uri> updatedUris,
  List<String> expectedUpdatedUris,
}) async {
  mainUri ??= Uri.parse('/path/to/main.dart');
  updatedUris ??= <Uri>[mainUri];
  expectedUpdatedUris ??= <String>[expectedMainUri];

  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.recompile(
    mainUri,
    updatedUris,
    outputPath: '/build/',
    packageConfig: PackageConfig.empty,
    suppressErrors: suppressErrors,
  );
  expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  final String commands = frontendServerStdIn.getAndClear();
  final RegExp whitespace = RegExp(r'\s+');
  final List<String> parts = commands.split(whitespace);

  // Test that uuid matches at beginning and end.
  expect(parts[2], equals(parts[3 + updatedUris.length]));
  expect(parts[1], equals(expectedMainUri));
  for (int i = 0; i < expectedUpdatedUris.length; i++) {
    expect(parts[3 + i], equals(expectedUpdatedUris[i]));
  }
  frontendServerStdIn.clear();
}

Future<void> _accept(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MemoryIOSink frontendServerStdIn,
  String expected,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  generator.accept();
  final String commands = frontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  frontendServerStdIn.clear();
}

Future<void> _reject(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MemoryIOSink frontendServerStdIn,
  String mockCompilerOutput,
  String expected,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.reject();
  expect(output, isNull);
  final String commands = frontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  frontendServerStdIn.clear();
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
