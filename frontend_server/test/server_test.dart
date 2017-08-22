import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/src/arg_results.dart';
import 'package:frontend_server/server.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockedCompiler extends Mock implements CompilerInterface {}

class _MockedIncrementalKernelGenerator extends Mock
  implements IncrementalKernelGenerator {}

class _MockedKernelSerializer extends Mock implements KernelSerializer {}

Future<int> main() async {
  group('basic', () {
    test('train completes', () async {
      expect(await starter(<String>['--train']), equals(0));
    });
  });

  group('batch compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    test('compile from command line', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
      ];
      final int exitcode = await starter(args, compiler: compiler);
      expect(exitcode, equals(0));
      final List<ArgResults> capturedArgs =
        verify(
          compiler.compile(
            argThat(equals('server.dart')),
            captureAny,
            generator: any,
          )
        ).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
    });
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
      new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      when(compiler.compile(any, any, generator: any)).thenAnswer(
        (Invocation invocation) {
          expect(invocation.positionalArguments[0], equals('server.dart'));
          expect(invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
          compileCalled.sendPort.send(true);
        }
      );

      final int exitcode = await starter(args, compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.close();
    });

    test('compile few files', () async {
      final StreamController<List<int>> streamController =
      new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      int counter = 1;
      when(compiler.compile(any, any, generator: any)).thenAnswer(
        (Invocation invocation) {
          expect(invocation.positionalArguments[0], equals('server${counter++}.dart'));
          expect(invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
          compileCalled.sendPort.send(true);
        }
      );

      final int exitcode = await starter(args, compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('compile server1.dart\n'.codeUnits);
      streamController.add('compile server2.dart\n'.codeUnits);
      await compileCalled.first;
      streamController.close();
    });
  });

  group('interactive incremental compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental'
    ];

    test('recompile few files', () async {
      final StreamController<List<int>> streamController =
        new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta()).thenAnswer((Invocation invocation) {
        recompileCalled.sendPort.send(true);
      });
      final int exitcode = await starter(args, compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(
        <dynamic>[
          compiler.invalidate(Uri.base.resolve('file1.dart')),
          compiler.invalidate(Uri.base.resolve('file2.dart')),
          compiler.recompileDelta(),
        ]
      );
      streamController.close();
    });

    test('accept', () async {
      final StreamController<List<int>> inputStreamController =
        new StreamController<List<int>>();
      final ReceivePort acceptCalled = new ReceivePort();
      when(compiler.acceptLastDelta()).thenAnswer((Invocation invocation) {
        acceptCalled.sendPort.send(true);
      });
      final int exitcode = await starter(args, compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('accept\n'.codeUnits);
      await acceptCalled.first;
      inputStreamController.close();
    });

    test('reject', () async {
      final StreamController<List<int>> inputStreamController =
      new StreamController<List<int>>();
      final ReceivePort rejectCalled = new ReceivePort();
      when(compiler.rejectLastDelta()).thenAnswer((Invocation invocation) {
        rejectCalled.sendPort.send(true);
      });
      final int exitcode = await starter(args, compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('reject\n'.codeUnits);
      await rejectCalled.first;
      inputStreamController.close();
    });

    test('compile then recompile', () async {
      final StreamController<List<int>> streamController =
      new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta()).thenAnswer((Invocation invocation) {
        recompileCalled.sendPort.send(true);
      });
      final int exitcode = await starter(args, compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('compile file1.dart\n'.codeUnits);
      streamController.add('accept\n'.codeUnits);
      streamController.add('recompile def\nfile2.dart\nfile3.dart\ndef\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<dynamic>[
        compiler.compile('file1.dart', any, generator: any),
        compiler.acceptLastDelta(),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        compiler.invalidate(Uri.base.resolve('file3.dart')),
        compiler.recompileDelta(),
      ]);
      streamController.close();
    });
  });

  group('interactive incremental compile with mocked IKG', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental',
    ];

    test('compile then accept', () async {
      final StreamController<List<int>> streamController =
        new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
        new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      ReceivePort receivedResult = new ReceivePort();

      String boundaryKey;
      stdoutStreamController.stream
        .transform(UTF8.decoder)
        .transform(new LineSplitter())
        .listen((String s) {
          const String RESULT_OUTPUT_SPACE = 'result ';
          if (boundaryKey == null) {
            if (s.startsWith(RESULT_OUTPUT_SPACE)) {
              boundaryKey = s.substring(RESULT_OUTPUT_SPACE.length);
            }
          } else {
            if (s == boundaryKey) {
              boundaryKey = null;
              receivedResult.sendPort.send(true);
            }
          }
        });

      final _MockedIncrementalKernelGenerator generator =
        new _MockedIncrementalKernelGenerator();
      when(generator.computeDelta()).thenReturn(new Future<DeltaProgram>.value(
        new DeltaProgram(null /* program stub */)
      ));
      final int exitcode = await starter(args, compiler: null,
        input: streamController.stream,
        output: ioSink,
        generator: generator,
        kernelSerializer: new _MockedKernelSerializer()
      );
      expect(exitcode, equals(0));

      streamController.add('compile file1.dart\n'.codeUnits);
      await receivedResult.first;
      streamController.add('accept\n'.codeUnits);
      receivedResult = new ReceivePort();
      streamController.add('recompile def\nfile1.dart\ndef\n'.codeUnits);
      await receivedResult.first;

      streamController.close();
    });

  });
  return 0;
}
