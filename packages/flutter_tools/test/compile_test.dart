// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'src/common.dart';
import 'src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;

void main() {
  group('batch compile', () {
    ProcessManager mockProcessManager;
    MockProcess mockFrontendServer;
    MockStdIn mockFrontendServerStdIn;
    MockStream mockFrontendServerStdErr;
    setUp(() {
      mockProcessManager = MockProcessManager();
      mockFrontendServer = MockProcess();
      mockFrontendServerStdIn = MockStdIn();
      mockFrontendServerStdErr = MockStream();

      when(mockFrontendServer.stderr)
          .thenAnswer((Invocation invocation) => mockFrontendServerStdErr);
      final StreamController<String> stdErrStreamController = StreamController<String>();
      when(mockFrontendServerStdErr.transform<String>(any)).thenAnswer((_) => stdErrStreamController.stream);
      when(mockFrontendServer.stdin).thenReturn(mockFrontendServerStdIn);
      when(mockProcessManager.canRun(any)).thenReturn(true);
      when(mockProcessManager.start(any)).thenAnswer(
          (Invocation invocation) => Future<Process>.value(mockFrontendServer));
      when(mockFrontendServer.exitCode).thenAnswer((_) async => 0);
    });

    testUsingContext('single dart successful compilation', () async {
      final BufferLogger logger = context[Logger];
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0'
            ))
          ));
      final CompilerOutput output = await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        trackWidgetCreation: false,
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
      expect(output.outputFilename, equals('/path/to/main.dart.dill'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('single dart failed compilation', () async {
      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc'
            ))
          ));

      final CompilerOutput output = await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        trackWidgetCreation: false,
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('single dart abnormal compiler termination', () async {
      when(mockFrontendServer.exitCode).thenAnswer((_) async => 255);

      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc'
          ))
      ));

      final CompilerOutput output = await kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        trackWidgetCreation: false,
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });
  });

  group('incremental compile', () {
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
      stdErrStreamController = StreamController<String>();
      when(mockFrontendServerStdErr.transform<String>(any))
          .thenAnswer((Invocation invocation) => stdErrStreamController.stream);

      when(mockProcessManager.canRun(any)).thenReturn(true);
      when(mockProcessManager.start(any)).thenAnswer(
          (Invocation invocation) => Future<Process>.value(mockFrontendServer)
      );
    });

    tearDown(() {
      verifyNever(mockFrontendServer.exitCode);
    });

    testUsingContext('single dart compile', () async {
      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0'
            ))
          ));

      final CompilerOutput output = await generator.recompile(
        '/path/to/main.dart',
          null /* invalidatedFiles */,
        outputPath: '/build/',
      );
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');
      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(logger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
      expect(output.outputFilename, equals('/path/to/main.dart.dill'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('single dart compile abnormally terminates', () async {
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
      );

      final CompilerOutput output = await generator.recompile(
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      );
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('compile and recompile', () async {
      final BufferLogger logger = context[Logger];

      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc /path/to/main.dart.dill 0\n'));
      await generator.recompile(
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      );
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0\n');

      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals(
        '\nCompiler message:\nline0\nline1\n'
        '\nCompiler message:\nline1\nline2\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('compile and recompile twice', () async {
      final BufferLogger logger = context[Logger];

      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode(
        'result abc\nline0\nline1\nabc /path/to/main.dart.dill 0\n'
      ));
      await generator.recompile('/path/to/main.dart', null /* invalidatedFiles */, outputPath: '/build/');
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0\n');
      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline2\nline3\nabc /path/to/main.dart.dill 0\n');

      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals(
        '\nCompiler message:\nline0\nline1\n'
        '\nCompiler message:\nline1\nline2\n'
        '\nCompiler message:\nline2\nline3\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });
  });

  group('compile expression', ()
  {
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
      stdErrStreamController = StreamController<String>();
      when(mockFrontendServerStdErr.transform<String>(any))
          .thenAnswer((Invocation invocation) => stdErrStreamController.stream);

      when(mockProcessManager.canRun(any)).thenReturn(true);
      when(mockProcessManager.start(any)).thenAnswer(
              (Invocation invocation) =>
          Future<Process>.value(mockFrontendServer)
      );
    });

    tearDown(() {
      verifyNever(mockFrontendServer.exitCode);
    });

    testUsingContext('fails if not previously compiled', () async {
      final CompilerOutput result = await generator.compileExpression(
          '2+2', null, null, null, null, false);
      expect(result, isNull);
    });

    testUsingContext('compile single expression', () async {
      final BufferLogger logger = context[Logger];

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
        'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0\n'
      )));

      await generator.recompile(
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      ).then((CompilerOutput output) {
        expect(mockFrontendServerStdIn.getAndClear(),
            'compile /path/to/main.dart\n');
        verifyNoMoreInteractions(mockFrontendServerStdIn);
        expect(logger.errorText,
            equals('\nCompiler message:\nline1\nline2\n'));
        expect(output.outputFilename, equals('/path/to/main.dart.dill'));

        compileExpressionResponseCompleter.complete(
            Future<List<int>>.value(utf8.encode(
                'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'
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
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('compile expressions without awaiting', () async {
      final BufferLogger logger = context[Logger];

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
      generator.recompile( // ignore: unawaited_futures
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      ).then((CompilerOutput outputCompile) {
        expect(logger.errorText,
            equals('\nCompiler message:\nline1\nline2\n'));
        expect(outputCompile.outputFilename, equals('/path/to/main.dart.dill'));

        compileExpressionResponseCompleter1.complete(Future<List<int>>.value(utf8.encode(
            'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'
        )));
      });

      // The test manages timing via completers.
      final Completer<bool> lastExpressionCompleted = Completer<bool>();
      generator.compileExpression('0+1', null, null, null, null, false).then( // ignore: unawaited_futures
          (CompilerOutput outputExpression) {
            expect(outputExpression, isNotNull);
            expect(outputExpression.outputFilename,
                equals('/path/to/main.dart.dill.incremental'));
            expect(outputExpression.errorCount, 0);
            compileExpressionResponseCompleter2.complete(Future<List<int>>.value(utf8.encode(
                'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'
            )));
          });

      // The test manages timing via completers.
      generator.compileExpression('1+1', null, null, null, null, false).then( // ignore: unawaited_futures
          (CompilerOutput outputExpression) {
            expect(outputExpression, isNotNull);
            expect(outputExpression.outputFilename,
                equals('/path/to/main.dart.dill.incremental'));
            expect(outputExpression.errorCount, 0);
            lastExpressionCompleted.complete(true);
          });

      compileResponseCompleter.complete(Future<List<int>>.value(utf8.encode(
          'result abc\nline1\nline2\nabc /path/to/main.dart.dill 0\n'
      )));

      expect(await lastExpressionCompleted.future, isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });
  });
}

Future<void> _recompile(StreamController<List<int>> streamController,
  ResidentCompiler generator, MockStdIn mockFrontendServerStdIn,
  String mockCompilerOutput) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.recompile(
    null /* mainPath */,
    <String>['/path/to/main.dart'],
    outputPath: '/build/',
  );
  expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp('^recompile (.*)\\n/path/to/main.dart\\n(.*)\\n\$');
  expect(commands, matches(re));
  final Match match = re.firstMatch(commands);
  expect(match[1] == match[2], isTrue);
  mockFrontendServerStdIn._stdInWrites.clear();
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockStream extends Mock implements Stream<List<int>> {}
class MockStdIn extends Mock implements IOSink {
  final StringBuffer _stdInWrites = StringBuffer();

  String getAndClear() {
    final String result = _stdInWrites.toString();
    _stdInWrites.clear();
    return result;
  }

  @override
  void write([Object o = '']) {
    _stdInWrites.write(o);
  }

  @override
  void writeln([Object o = '']) {
    _stdInWrites.writeln(o);
  }
}
