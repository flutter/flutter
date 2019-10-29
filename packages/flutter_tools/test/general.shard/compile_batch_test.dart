// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
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

  testUsingContext('batch compile single dart successful compilation', () async {
    final BufferLogger bufferLogger = logger;
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
          ))
        ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    final CompilerOutput output = await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(bufferLogger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
    expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('passes no-gen-bytecode to kernel compiler in aot/release mode', () async {
    when(mockFrontendServer.stdout)
      .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
        Future<List<int>>.value(utf8.encode(
          'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
        ))
      ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.release,
      trackWidgetCreation: false,
      aot: true,
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    final VerificationResult argVerification = verify(mockProcessManager.start(captureAny));
    expect(argVerification.captured.single, contains('--no-gen-bytecode'));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('batch compile single dart failed compilation', () async {
    final BufferLogger bufferLogger = logger;
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc'
          ))
        ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    final CompilerOutput output = await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(bufferLogger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
    expect(output, equals(null));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('batch compile single dart abnormal compiler termination', () async {
    when(mockFrontendServer.exitCode).thenAnswer((_) async => 255);
    final BufferLogger bufferLogger = logger;

    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
        Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc'
        ))
    ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    final CompilerOutput output = await kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
    );
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(bufferLogger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
    expect(output, equals(null));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
