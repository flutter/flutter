// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('batch compile', () {
    ProcessManager mockProcessManager;
    MockProcess mockFrontendServer;
    MockStdIn mockFrontendServerStdIn;
    MockStream mockFrontendServerStdErr;
    setUp(() {
      mockProcessManager = new MockProcessManager();
      mockFrontendServer = new MockProcess();
      mockFrontendServerStdIn = new MockStdIn();
      mockFrontendServerStdErr = new MockStream();

      when(mockFrontendServer.stderr)
          .thenAnswer((Invocation invocation) => mockFrontendServerStdErr);
      final StreamController<String> stdErrStreamController = new StreamController<String>();
      when(mockFrontendServerStdErr.transform<String>(any)).thenReturn(stdErrStreamController.stream);
      when(mockFrontendServer.stdin).thenReturn(mockFrontendServerStdIn);
      when(mockProcessManager.start(any)).thenAnswer(
          (Invocation invocation) => new Future<Process>.value(mockFrontendServer));
      when(mockFrontendServer.exitCode).thenReturn(0);
    });

    testUsingContext('single dart successful compilation', () async {
      final BufferLogger logger = context[Logger];
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => new Stream<List<int>>.fromFuture(
            new Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc /path/to/main.dart.dill'
            ))
          ));
      final String output = await compile(sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart'
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('compiler message: line1\ncompiler message: line2\n'));
      expect(output, equals('/path/to/main.dart.dill'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('single dart failed compilation', () async {
      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => new Stream<List<int>>.fromFuture(
            new Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc'
            ))
          ));

      final String output = await compile(sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart'
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('compiler message: line1\ncompiler message: line2\n'));
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('single dart abnormal compiler termination', () async {
      when(mockFrontendServer.exitCode).thenReturn(255);

      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => new Stream<List<int>>.fromFuture(
          new Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc'
          ))
      ));

      final String output = await compile(sdkRoot: '/path/to/sdkroot',
          mainPath: '/path/to/main.dart'
      );
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals('compiler message: line1\ncompiler message: line2\n'));
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
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
      generator = new ResidentCompiler('sdkroot');
      mockProcessManager = new MockProcessManager();
      mockFrontendServer = new MockProcess();
      mockFrontendServerStdIn = new MockStdIn();
      mockFrontendServerStdErr = new MockStream();

      when(mockFrontendServer.stdin).thenReturn(mockFrontendServerStdIn);
      when(mockFrontendServer.stderr)
          .thenAnswer((Invocation invocation) => mockFrontendServerStdErr);
      stdErrStreamController = new StreamController<String>();
      when(mockFrontendServerStdErr.transform<String>(any))
          .thenAnswer((Invocation invocation) => stdErrStreamController.stream);

      when(mockProcessManager.start(any)).thenAnswer(
          (Invocation invocation) => new Future<Process>.value(mockFrontendServer)
      );
    });

    tearDown(() {
      verifyNever(mockFrontendServer.exitCode);
    });

    testUsingContext('single dart compile', () async {
      final BufferLogger logger = context[Logger];

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => new Stream<List<int>>.fromFuture(
            new Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc /path/to/main.dart.dill'
            ))
          ));

      final String output = await generator.recompile(
        '/path/to/main.dart', null /* invalidatedFiles */
      );
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');
      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(logger.errorText, equals('compiler message: line1\ncompiler message: line2\n'));
      expect(output, equals('/path/to/main.dart.dill'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('single dart compile abnormally terminates', () async {
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
      );

      final String output = await generator.recompile(
          '/path/to/main.dart', null /* invalidatedFiles */
      );
      expect(output, equals(null));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('compile and recompile', () async {
      final BufferLogger logger = context[Logger];

      final StreamController<List<int>> streamController = new StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc /path/to/main.dart.dill\n'));
      await generator.recompile('/path/to/main.dart', null /* invalidatedFiles */);
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc /path/to/main.dart.dill\n');

      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals(
        'compiler message: line0\ncompiler message: line1\n'
        'compiler message: line1\ncompiler message: line2\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('compile and recompile twice', () async {
      final BufferLogger logger = context[Logger];

      final StreamController<List<int>> streamController = new StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode(
        'result abc\nline0\nline1\nabc /path/to/main.dart.dill\n'
      ));
      await generator.recompile('/path/to/main.dart', null /* invalidatedFiles */);
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc /path/to/main.dart.dill\n');
      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline2\nline3\nabc /path/to/main.dart.dill\n');

      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals(
        'compiler message: line0\ncompiler message: line1\n'
        'compiler message: line1\ncompiler message: line2\n'
        'compiler message: line2\ncompiler message: line3\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });
}

Future<Null> _recompile(StreamController<List<int>> streamController,
  ResidentCompiler generator, MockStdIn mockFrontendServerStdIn,
  String mockCompilerOutput) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  new Future<List<int>>(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final String output = await generator.recompile(null /* mainPath */, <String>['/path/to/main.dart']);
  expect(output, equals('/path/to/main.dart.dill'));
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = new RegExp(r'^recompile (.*)\n/path/to/main.dart\n(.*)\n$');
  expect(commands, matches(re));
  final Match match = re.firstMatch(commands);
  expect(match[1] == match[2], isTrue);
  mockFrontendServerStdIn._stdInWrites.clear();
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockStream extends Mock implements Stream<List<int>> {}
class MockStdIn extends Mock implements IOSink {
  final StringBuffer _stdInWrites = new StringBuffer();

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
