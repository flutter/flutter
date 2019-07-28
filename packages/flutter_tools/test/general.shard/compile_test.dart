// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;

void main() {
  group(PackageUriMapper, () {
    group('single-root', () {
      const String packagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:file:///example/lib/
''';
      final MockFileSystem mockFileSystem = MockFileSystem();
      final MockFile mockFile = MockFile();
      when(mockFileSystem.path).thenReturn(fs.path);
      when(mockFileSystem.file(any)).thenReturn(mockFile);
      when(mockFile.readAsBytesSync()).thenReturn(utf8.encode(packagesContents));
      testUsingContext('Can map main.dart to correct package', () async {
        final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
        expect(packageUriMapper.map('/example/lib/main.dart').toString(), 'package:example/main.dart');
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
      });

      testUsingContext('Maps file from other package to null', () async {
        final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
        expect(packageUriMapper.map('/xml/lib/xml.dart'),  null);
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
      });

      testUsingContext('Maps non-main file from same package', () async {
        final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
        expect(packageUriMapper.map('/example/lib/src/foo.dart').toString(), 'package:example/src/foo.dart');
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
      });
    });

    group('multi-root', () {
      final MockFileSystem mockFileSystem = MockFileSystem();
      final MockFile mockFile = MockFile();
      when(mockFileSystem.path).thenReturn(fs.path);
      when(mockFileSystem.file(any)).thenReturn(mockFile);

      const String multiRootPackagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:org-dartlang-app:/
''';
      when(mockFile.readAsBytesSync()).thenReturn(utf8.encode(multiRootPackagesContents));

      testUsingContext('Maps main file from same package on multiroot scheme', () async {
        final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', 'org-dartlang-app', <String>['/example/lib/', '/gen/lib/']);
        expect(packageUriMapper.map('/example/lib/main.dart').toString(), 'package:example/main.dart');
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
      });
    });
  });

  testUsingContext('StdOutHandler test', () async {
    final StdoutHandler stdoutHandler = StdoutHandler();
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 0');
    final CompilerOutput output = await stdoutHandler.compilerOutput.future;
    expect(output.errorCount, 0);
    expect(output.outputFilename, 'message');
  }, overrides: <Type, Generator>{
    Logger: () => BufferLogger(),
  });

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
      final BufferLogger logger = context.get<Logger>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
            ))
          ));
      final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
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
      final BufferLogger logger = context.get<Logger>();

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc\nabc'
            ))
          ));
      final KernelCompiler kernelCompiler = await kernelCompilerFactory.create(null);
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

      final BufferLogger logger = context.get<Logger>();

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
      final BufferLogger logger = context.get<Logger>();

      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
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
      final BufferLogger logger = context.get<Logger>();

      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));
      await generator.recompile(
        '/path/to/main.dart',
        null, /* invalidatedFiles */
        outputPath: '/build/',
      );
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      // No accept or reject commands should be issued until we
      // send recompile request.
      await _accept(streamController, generator, mockFrontendServerStdIn, '');
      await _reject(streamController, generator, mockFrontendServerStdIn, '', '');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

      await _accept(streamController, generator, mockFrontendServerStdIn, '^accept\\n\$');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
          'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

      await _reject(streamController, generator, mockFrontendServerStdIn, 'result abc\nabc\nabc\nabc',
          '^reject\\n\$');

      verifyNoMoreInteractions(mockFrontendServerStdIn);
      expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
      expect(logger.errorText, equals(
        '\nCompiler message:\nline0\nline1\n'
        '\nCompiler message:\nline1\nline2\n'
        '\nCompiler message:\nline1\nline2\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('compile and recompile twice', () async {
      final BufferLogger logger = context.get<Logger>();

      final StreamController<List<int>> streamController = StreamController<List<int>>();
      when(mockFrontendServer.stdout)
          .thenAnswer((Invocation invocation) => streamController.stream);
      streamController.add(utf8.encode(
        'result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'
      ));
      await generator.recompile('/path/to/main.dart', null /* invalidatedFiles */, outputPath: '/build/');
      expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
      await _recompile(streamController, generator, mockFrontendServerStdIn,
        'result abc\nline2\nline3\nabc\nabc /path/to/main.dart.dill 0\n');

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

  group('compile expression', () {
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
      final BufferLogger logger = context.get<Logger>();

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
        expect(logger.errorText,
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
      Platform: _kNoColorTerminalPlatform,
    });

    testUsingContext('compile expressions without awaiting', () async {
      final BufferLogger logger = context.get<Logger>();

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
          expect(logger.errorText,
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
        )
      );

      compileResponseCompleter.complete(Future<List<int>>.value(utf8.encode(
          'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n'
      )));

      expect(await lastExpressionCompleted.future, isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(showColor: false),
      Logger: () => BufferLogger(),
      Platform: _kNoColorTerminalPlatform,
    });
  });

  test('TargetModel values', () {
    expect(TargetModel('vm'), TargetModel.vm);
    expect(TargetModel.vm.toString(), 'vm');

    expect(TargetModel('flutter'), TargetModel.flutter);
    expect(TargetModel.flutter.toString(), 'flutter');

    expect(TargetModel('flutter_runner'), TargetModel.flutterRunner);
    expect(TargetModel.flutterRunner.toString(), 'flutter_runner');
    expect(() => TargetModel('foobar'), throwsA(isInstanceOf<AssertionError>()));
  });
}

Future<void> _recompile(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
  String mockCompilerOutput,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.recompile(
    null /* mainPath */,
    <Uri>[Uri.parse('/path/to/main.dart')],
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
  mockFrontendServerStdIn._stdInWrites.clear();
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
  void write([ Object o = '' ]) {
    _stdInWrites.write(o);
  }

  @override
  void writeln([ Object o = '' ]) {
    _stdInWrites.writeln(o);
  }
}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
