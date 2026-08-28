// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

void main() {
  late FakeProcessManager processManager;
  late ResidentCompiler generator;
  late MemoryIOSink frontendServerStdIn;
  late StreamController<String> stdErrStreamController;
  late BufferLogger testLogger;
  late MemoryFileSystem fileSystem;

  setUp(() {
    testLogger = BufferLogger.test();
    processManager = FakeProcessManager();
    frontendServerStdIn = MemoryIOSink();
    fileSystem = MemoryFileSystem.test()
      ..file(Artifact.flutterPatchedSdkPath.toString()).createSync();
    generator = const ResidentCompilerFactory().create(
      targetPlatform: .tester,
      buildInfo: BuildInfo.debug,
      artifacts: Artifacts.test(fileSystem: fileSystem),
      processManager: processManager,
      logger: testLogger,
      platform: FakePlatform(),
      fileSystem: fileSystem,
      shutdownHooks: FakeShutdownHooks(),
      config: Config.test(),
    );

    stdErrStreamController = StreamController<String>();
    processManager.process.stdin = frontendServerStdIn;
    processManager.process.stderr = stdErrStreamController.stream.transform(utf8.encoder);
  });

  testWithoutContext('compile expression fails if not previously compiled', () async {
    final CompilerOutput? result = await generator.compileExpression(
      '2+2',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
    );

    expect(result, isNull);
  });

  testWithoutContext('compile expression can compile single expression', () async {
    final stdoutController = StreamController<List<int>>();
    processManager.process.stdout = stdoutController.stream;

    fileSystem.file('/path/to/main.dart.dill')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);

    final Future<CompilerOutput?> compileFuture = generator.recompile(
      Uri.file('/path/to/main.dart'),
      null,
      /* invalidatedFiles */
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
      projectRootPath: '',
      fs: fileSystem,
    );
    stdoutController.add(
      utf8.encode('result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'),
    );
    final CompilerOutput? output = await compileFuture;
    expect(frontendServerStdIn.getAndClear(), 'compile file:///path/to/main.dart\n');
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output!.outputFilename, equals('/path/to/main.dart.dill'));

    fileSystem.file('/path/to/main.dart.dill.incremental')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);

    final Future<CompilerOutput?> expressionFuture = generator.compileExpression(
      '2+2',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      false,
    );
    stdoutController.add(
      utf8.encode('result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'),
    );
    final CompilerOutput? outputExpression = await expressionFuture;
    expect(outputExpression, isNotNull);
    expect(outputExpression!.expressionData, <int>[1, 2, 3, 4]);

    final List<String> stdinLines = frontendServerStdIn.getAndClear().trim().split('\n');
    expect(stdinLines, hasLength(2));
    expect(stdinLines[0], 'JSON_INPUT');
    expect(
      json.decode(stdinLines[1]),
      <String, Object?>{
        'type': 'COMPILE_EXPRESSION',
        'data': <String, Object?>{
          'expression': '2+2',
          'definitions': <String>[],
          'definitionTypes': <String>[],
          'typeDefinitions': <String>[],
          'typeBounds': <String>[],
          'typeDefaults': <String>[],
          'libraryUri': '',
          'class': null,
          'method': null,
          'static': false,
        },
      },
    );
    await stdoutController.close();
  });

  testWithoutContext('compile expression sends JSON_INPUT for multiline expressions', () async {
    final stdoutController = StreamController<List<int>>();
    processManager.process.stdout = stdoutController.stream;

    fileSystem.file('/path/to/main.dart.dill')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    fileSystem.file('/path/to/main.dart.dill.incremental')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);

    final Future<CompilerOutput?> compileFuture = generator.recompile(
      Uri.file('/path/to/main.dart'),
      null,
      /* invalidatedFiles */
      outputPath: '/build/',
      packageConfig: PackageConfig.empty,
      projectRootPath: '',
      fs: fileSystem,
    );
    stdoutController.add(
      utf8.encode('result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'),
    );
    final CompilerOutput? output = await compileFuture;
    expect(frontendServerStdIn.getAndClear(), 'compile file:///path/to/main.dart\n');
    expect(testLogger.errorText, equals('line1\nline2\n'));
    expect(output!.outputFilename, equals('/path/to/main.dart.dill'));

    const multilineExpression = 'final a = 1;\nfinal b = 2;\na + b;';
    final Future<CompilerOutput?> expressionFuture = generator.compileExpression(
      multilineExpression,
      <String>['def1'],
      <String>['int'],
      <String>['TypeDef1'],
      <String>['TypeBound1'],
      <String>['TypeDefault1'],
      'package:foo/foo.dart',
      'FooClass',
      'fooMethod',
      false,
    );
    stdoutController.add(
      utf8.encode('result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n'),
    );
    final CompilerOutput? outputExpression = await expressionFuture;

    expect(outputExpression, isNotNull);
    expect(outputExpression!.expressionData, <int>[1, 2, 3, 4]);

    final List<String> stdinLines = frontendServerStdIn.getAndClear().trim().split('\n');
    expect(stdinLines, hasLength(2));
    expect(stdinLines[0], 'JSON_INPUT');
    expect(
      json.decode(stdinLines[1]),
      <String, Object?>{
        'type': 'COMPILE_EXPRESSION',
        'data': <String, Object?>{
          'expression': multilineExpression,
          'definitions': <String>['def1'],
          'definitionTypes': <String>['int'],
          'typeDefinitions': <String>['TypeDef1'],
          'typeBounds': <String>['TypeBound1'],
          'typeDefaults': <String>['TypeDefault1'],
          'libraryUri': 'package:foo/foo.dart',
          'class': 'FooClass',
          'method': 'fooMethod',
          'static': false,
        },
      },
    );
    await stdoutController.close();
  });

  testWithoutContext('compile expressions without awaiting', () async {
    final compileResponseCompleter = Completer<List<int>>();
    final compileExpressionResponseCompleter1 = Completer<List<int>>();
    final compileExpressionResponseCompleter2 = Completer<List<int>>();

    processManager.process.stdout = Stream<List<int>>.fromFutures(<Future<List<int>>>[
      compileResponseCompleter.future,
      compileExpressionResponseCompleter1.future,
      compileExpressionResponseCompleter2.future,
    ]);

    // The test manages timing via completers.
    unawaited(
      generator
          .recompile(
            Uri.parse('/path/to/main.dart'),
            null,
            /* invalidatedFiles */
            outputPath: '/build/',
            packageConfig: PackageConfig.empty,
            projectRootPath: '',
            fs: MemoryFileSystem(),
          )
          .then((CompilerOutput? outputCompile) {
            expect(testLogger.errorText, equals('line1\nline2\n'));
            expect(outputCompile!.outputFilename, equals('/path/to/main.dart.dill'));

            fileSystem.file('/path/to/main.dart.dill.incremental')
              ..createSync(recursive: true)
              ..writeAsBytesSync(<int>[0, 1, 2, 3]);
            compileExpressionResponseCompleter1.complete(
              Future<List<int>>.value(
                utf8.encode(
                  'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n',
                ),
              ),
            );
          }),
    );

    // The test manages timing via completers.
    final lastExpressionCompleted = Completer<bool>();
    unawaited(
      generator
          .compileExpression('0+1', null, null, null, null, null, null, null, null, false)
          .then((CompilerOutput? outputExpression) {
            expect(outputExpression, isNotNull);
            expect(outputExpression!.expressionData, <int>[0, 1, 2, 3]);

            fileSystem.file('/path/to/main.dart.dill.incremental')
              ..createSync(recursive: true)
              ..writeAsBytesSync(<int>[4, 5, 6, 7]);
            compileExpressionResponseCompleter2.complete(
              Future<List<int>>.value(
                utf8.encode(
                  'result def\nline1\nline2\ndef /path/to/main.dart.dill.incremental 0\n',
                ),
              ),
            );
          }),
    );

    // The test manages timing via completers.
    unawaited(
      generator
          .compileExpression('1+1', null, null, null, null, null, null, null, null, false)
          .then((CompilerOutput? outputExpression) {
            expect(outputExpression, isNotNull);
            expect(outputExpression!.expressionData, <int>[4, 5, 6, 7]);
            lastExpressionCompleted.complete(true);
          }),
    );

    compileResponseCompleter.complete(
      Future<List<int>>.value(
        utf8.encode('result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'),
      ),
    );

    expect(await lastExpressionCompleted.future, isTrue);
  });
}

class FakeProcess extends Fake implements Process {
  @override
  Stream<List<int>> stdout = const Stream<List<int>>.empty();

  @override
  Stream<List<int>> stderr = const Stream<List<int>>.empty();

  @override
  IOSink stdin = IOSink(StreamController<List<int>>().sink);

  @override
  Future<int> get exitCode => Completer<int>().future;
}

class FakeProcessManager extends Fake implements ProcessManager {
  final process = FakeProcess();

  @override
  bool canRun(dynamic executable, {String? workingDirectory}) {
    return true;
  }

  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    return process;
  }
}
