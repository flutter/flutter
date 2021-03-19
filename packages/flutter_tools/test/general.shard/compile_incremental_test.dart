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
import '../src/mocks.dart';

void main() {
  ProcessManager mockProcessManager;
  ResidentCompiler generator;
  ResidentCompiler generatorWithScheme;
  MockProcess mockFrontendServer;
  MockStdIn mockFrontendServerStdIn;
  MockStream mockFrontendServerStdErr;
  StreamController<String> stdErrStreamController;
  BufferLogger testLogger;

  setUp(() {
    testLogger = BufferLogger.test();
    mockProcessManager = MockProcessManager();
    mockFrontendServer = MockProcess();
    mockFrontendServerStdIn = MockStdIn();
    mockFrontendServerStdErr = MockStream();
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

    when(mockFrontendServer.stdin).thenReturn(mockFrontendServerStdIn);
    when(mockFrontendServer.stderr)
        .thenAnswer((Invocation invocation) => mockFrontendServerStdErr);
    when(mockFrontendServer.exitCode).thenAnswer((Invocation invocation) {
      return Completer<int>().future;
    });
    stdErrStreamController = StreamController<String>();
    when(mockFrontendServerStdErr.transform<String>(any))
        .thenAnswer((Invocation invocation) => stdErrStreamController.stream);

    when(mockProcessManager.canRun(any)).thenReturn(true);
    when(mockProcessManager.start(any)).thenAnswer(
        (Invocation invocation) => Future<Process>.value(mockFrontendServer)
    );
  });

  testWithoutContext('incremental compile single dart compile', () async {
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
          ))
        ));

    final CompilerOutput output = await generator.recompile(
      Uri.parse('/path/to/main.dart'),
        null /* invalidatedFiles */,
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
    );
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  });

  testWithoutContext('incremental compile single dart compile with filesystem scheme', () async {
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
          ))
        ));

    final CompilerOutput output = await generatorWithScheme.recompile(
      Uri.parse('file:///foo/bar/fizz/main.dart'),
        null /* invalidatedFiles */,
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
    );
    expect(mockFrontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  });

  testWithoutContext('incremental compile single dart compile abnormally terminates', () async {
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
    );

    expect(asyncGuard(() => generator.recompile(
      Uri.parse('/path/to/main.dart'),
      null, /* invalidatedFiles */
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
    )), throwsToolExit());
  });

  testWithoutContext('incremental compile single dart compile abnormally terminates via exitCode', () async {
    when(mockFrontendServer.exitCode)
        .thenAnswer((Invocation invocation) async => 1);
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
    );

    expect(asyncGuard(() => generator.recompile(
      Uri.parse('/path/to/main.dart'),
      null, /* invalidatedFiles */
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
    )), throwsToolExit());
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
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

    // No accept or reject commands should be issued until we
    // send recompile request.
    await _accept(streamController, generator, mockFrontendServerStdIn, '');
    await _reject(streamController, generator, mockFrontendServerStdIn, '', '');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

    await _accept(streamController, generator, mockFrontendServerStdIn, r'^accept\n$');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
    // No sources returned from reject command.
    await _reject(streamController, generator, mockFrontendServerStdIn, 'result abc\nabc\n',
      r'^reject\n$');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
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
    expect(mockFrontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');

    // No accept or reject commands should be issued until we
    // send recompile request.
    await _accept(streamController, generatorWithScheme, mockFrontendServerStdIn, '');
    await _reject(streamController, generatorWithScheme, mockFrontendServerStdIn, '', '');

    await _recompile(streamController, generatorWithScheme, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
      mainUri: Uri.parse('file:///foo/bar/fizz/main.dart'),
      expectedMainUri: 'scheme:///main.dart');

    await _accept(streamController, generatorWithScheme, mockFrontendServerStdIn, r'^accept\n$');

    await _recompile(streamController, generatorWithScheme, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
      mainUri: Uri.parse('file:///foo/bar/fizz/main.dart'),
      expectedMainUri: 'scheme:///main.dart');
    // No sources returned from reject command.
    await _reject(streamController, generatorWithScheme, mockFrontendServerStdIn, 'result abc\nabc\n',
      r'^reject\n$');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
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
    expect(mockFrontendServerStdIn.getAndClear(), 'compile scheme:///main.dart\n');

    // No accept or reject commands should be issued until we
    // send recompile request.
    await _accept(streamController, generatorWithScheme, mockFrontendServerStdIn, '');
    await _reject(streamController, generatorWithScheme, mockFrontendServerStdIn, '', '');

    await _recompile(streamController, generatorWithScheme, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
      mainUri: mainUri,
      expectedMainUri: expectedMainUri,
      updatedUris: updatedUris,
      expectedUpdatedUris: expectedUpdatedUris);

    await _accept(streamController, generatorWithScheme, mockFrontendServerStdIn, r'^accept\n$');

    await _recompile(streamController, generatorWithScheme, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n',
      mainUri: mainUri,
      expectedMainUri: expectedMainUri,
      updatedUris: updatedUris,
      expectedUpdatedUris: expectedUpdatedUris);
    // No sources returned from reject command.
    await _reject(streamController, generatorWithScheme, mockFrontendServerStdIn, 'result abc\nabc\n',
      r'^reject\n$');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
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
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

    await _recompile(stdoutController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

    await _accept(stdoutController, generator, mockFrontendServerStdIn, r'^accept\n$');

    await _recompile(stdoutController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n', suppressErrors: true);

    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);

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
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline2\nline3\nabc\nabc /path/to/main.dart.dill 0\n');

    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals(
      'line0\nline1\n'
      'line1\nline2\n'
      'line2\nline3\n'
    ));
  });
}

Future<void> _recompile(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
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
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp whitespace = RegExp(r'\s+');
  final List<String> parts = commands.split(whitespace);

  // Test that uuid matches at beginning and end.
  expect(parts[2], equals(parts[3 + updatedUris.length]));
  expect(parts[1], equals(expectedMainUri));
  for (int i = 0; i < expectedUpdatedUris.length; i++) {
    expect(parts[3 + i], equals(expectedUpdatedUris[i]));
  }
  mockFrontendServerStdIn.stdInWrites.clear();
}

Future<void> _accept(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
  String expected,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  generator.accept();
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  mockFrontendServerStdIn.stdInWrites.clear();
}

Future<void> _reject(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
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
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  mockFrontendServerStdIn.stdInWrites.clear();
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
