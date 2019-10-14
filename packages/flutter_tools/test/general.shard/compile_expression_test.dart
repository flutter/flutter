// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  ProcessManager mockProcessManager;
  ResidentCompiler generator;
  MockProcess mockFrontendServer;
  MockStdIn mockFrontendServerStdIn;
  MockStream mockFrontendServerStdErr;
  StreamController<String> stdErrStreamController;

  setUp(() {
    generator = ResidentCompiler('sdkroot');
    mockProcessManager = MockProcessManager();
    mockFrontendServer = MockProcess();
    mockFrontendServerStdIn = MockStdIn();
    mockFrontendServerStdErr = MockStream();

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
            (Invocation invocation) =>
        Future<Process>.value(mockFrontendServer)
    );
  });

  testUsingContext('compile expression fails if not previously compiled', () async {
    final CompilerOutput result = await generator.compileExpression(
        '2+2', null, null, null, null, false);
    expect(result, isNull);
  });

  testUsingContext('compile expression can compile single expression', () async {
    final BufferLogger bufferLogger = logger;

    final Completer<List<int>> compileResponseCompleter =
        Completer<List<int>>();
    final Completer<List<int>> compileExpressionResponseCompleter =
        Completer<List<int>>();

    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) =>
    Stream<List<int>>.fromFutures(
      <Future<List<int>>>[
        compileResponseCompleter.future,
        compileExpressionResponseCompleter.future]));

    compileResponseCompleter.complete(Future<List<int>>.value(utf8.encode(
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'
    )));

    await generator.recompile(
      '/path/to/main.dart',
      null, /* invalidatedFiles */
      outputPath: '/build/',
    ).then((CompilerOutput output) {
      expect(mockFrontendServerStdIn.getAndClear(),
          'compile /path/to/main.dart\n');
      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(bufferLogger.errorText,
          equals('\nCompiler message:\nline1\nline2\n'));
      expect(output.outputFilename, equals('/path/to/main.dart.dill'));

      compileExpressionResponseCompleter.complete(
          Future<List<int>>.value(utf8.encode(
              'result def\nline1\nline2\ndef\ndef /path/to/main.dart.dill.incremental 0\n'
          )));
      generator.compileExpression(
          '2+2', null, null, null, null, false).then(
              (CompilerOutput outputExpression) {
                expect(outputExpression, isNotNull);
                expect(outputExpression.outputFilename, equals('/path/to/main.dart.dill.incremental'));
                expect(outputExpression.errorCount, 0);
              }
      );
    });

  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Logger: () => BufferLogger(),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('compile expressions without awaiting', () async {
    final BufferLogger bufferLogger = logger;
    final Completer<List<int>> compileResponseCompleter = Completer<List<int>>();
    final Completer<List<int>> compileExpressionResponseCompleter1 = Completer<List<int>>();
    final Completer<List<int>> compileExpressionResponseCompleter2 = Completer<List<int>>();

    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) =>
    Stream<List<int>>.fromFutures(
        <Future<List<int>>>[
          compileResponseCompleter.future,
          compileExpressionResponseCompleter1.future,
          compileExpressionResponseCompleter2.future,
        ]));

    // The test manages timing via completers.
    unawaited(
      generator.recompile(
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      ).then((CompilerOutput outputCompile) {
        expect(bufferLogger.errorText,
            equals('\nCompiler message:\nline1\nline2\n'));
        expect(outputCompile.outputFilename, equals('/path/to/main.dart.dill'));

        compileExpressionResponseCompleter1.complete(Future<List<int>>.value(utf8.encode(
            'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'
        )));
      }),
    );

    // The test manages timing via completers.
    final Completer<bool> lastExpressionCompleted = Completer<bool>();
    unawaited(
      generator.compileExpression('0+1', null, null, null, null, false).then(
        (CompilerOutput outputExpression) {
          expect(outputExpression, isNotNull);
          expect(outputExpression.outputFilename,
              equals('/path/to/main.dart.dill.incremental'));
          expect(outputExpression.errorCount, 0);
          compileExpressionResponseCompleter2.complete(Future<List<int>>.value(utf8.encode(
              'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'
          )));
        },
      ),
    );

    // The test manages timing via completers.
    unawaited(
      generator.compileExpression('1+1', null, null, null, null, false).then(
        (CompilerOutput outputExpression) {
          expect(outputExpression, isNotNull);
          expect(outputExpression.outputFilename,
              equals('/path/to/main.dart.dill.incremental'));
          expect(outputExpression.errorCount, 0);
          lastExpressionCompleted.complete(true);
        },
      ),
    );

    compileResponseCompleter.complete(Future<List<int>>.value(utf8.encode(
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'
    )));

    expect(await lastExpressionCompleted.future, isTrue);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
