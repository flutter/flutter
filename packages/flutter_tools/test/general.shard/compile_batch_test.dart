// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
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
  MockProcess mockFrontendServer;
  MockStdIn mockFrontendServerStdIn;
  MockStream mockFrontendServerStdErr;

  List<String> latestCommand;

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
        (Invocation invocation) {
          latestCommand = invocation.positionalArguments.first as List<String>;
          return Future<Process>.value(mockFrontendServer);
        });
    when(mockFrontendServer.exitCode).thenAnswer((_) async => 0);
  });

  testUsingContext('batch compile single dart successful compilation', () async {
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
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output.outputFilename, equals('/path/to/main.dart.dill'));
    final VerificationResult argVerification = verify(mockProcessManager.start(captureAny));
    expect(argVerification.captured.single, containsAll(<String>[
      '-Ddart.developer.causal_async_stacks=true',
    ]));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });

  testUsingContext('passes correct AOT config to kernel compiler in aot/profile mode', () async {
    when(mockFrontendServer.stdout)
      .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
        Future<List<int>>.value(utf8.encode(
          'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
        ))
      ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.profile,
      trackWidgetCreation: false,
      aot: true,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    final VerificationResult argVerification = verify(mockProcessManager.start(captureAny));
    expect(argVerification.captured.single, containsAll(<String>[
      '--aot',
      '--tfa',
      '-Ddart.vm.profile=true',
      '-Ddart.vm.product=false',
      '--bytecode-options=source-positions',
      '-Ddart.developer.causal_async_stacks=false',
    ]));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });


  testUsingContext('passes correct AOT config to kernel compiler in aot/release mode', () async {
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
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    final VerificationResult argVerification = verify(mockProcessManager.start(captureAny));
    expect(argVerification.captured.single, containsAll(<String>[
      '--aot',
      '--tfa',
      '-Ddart.vm.profile=false',
      '-Ddart.vm.product=true',
      '--bytecode-options=source-positions',
      '-Ddart.developer.causal_async_stacks=false',
    ]));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });

  testUsingContext('batch compile single dart failed compilation', () async {
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
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );

    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output, equals(null));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });

  testUsingContext('batch compile single dart abnormal compiler termination', () async {
    when(mockFrontendServer.exitCode).thenAnswer((_) async => 255);

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
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output, equals(null));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });

  testUsingContext('passes dartDefines to the kernel compiler', () async {
    // Use unsuccessful result because it's easier to setup in test. We only care about arguments passed to the compiler.
    when(mockFrontendServer.exitCode).thenAnswer((_) async => 255);
    when(mockFrontendServer.stdout).thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
      Future<List<int>>.value(<int>[])
    ));
    final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
    await kernelCompiler.compile(sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>['FOO=bar', 'BAZ=qux'],
      packageConfig: PackageConfig.empty,
      packagesPath: '.packages',
    );

    expect(latestCommand, containsAllInOrder(<String>['-DFOO=bar', '-DBAZ=qux']));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
    Artifacts: () => Artifacts.test(),
  });
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
