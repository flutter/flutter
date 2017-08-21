import 'dart:async';
import 'dart:isolate';

import 'package:args/src/arg_results.dart';
import 'package:frontend_server/server.dart';
import 'package:test/test.dart';

class _MockedCompiler implements CompilerInterface {
  _MockedCompiler({
    this.compileCallback,
    this.recompileDeltaCallback,
    this.acceptLastDeltaCallback,
    this.rejectLastDeltaCallback,
    this.invalidateCallback
  });

  Future<Null> Function(String, ArgResults) compileCallback;
  Future<Null> Function() recompileDeltaCallback;
  void Function() acceptLastDeltaCallback;
  void Function() rejectLastDeltaCallback;
  void Function(Uri) invalidateCallback;

  @override
  Future<Null> compile(String filename, ArgResults options) {
    return compileCallback != null
        ? compileCallback(filename, options)
        : new Future<Null>.value(null);
  }

  @override
  void invalidate(Uri uri) {
    if (invalidateCallback != null)
      invalidateCallback(uri);
  }

  @override
  Future<Null> recompileDelta() {
    return recompileDeltaCallback != null
        ? recompileDeltaCallback()
        : new Future<Null>.value(null);
  }

  @override
  void acceptLastDelta() {
    if (acceptLastDeltaCallback != null)
      acceptLastDeltaCallback();
  }

  @override
  void rejectLastDelta() {
    if (rejectLastDeltaCallback != null)
      rejectLastDeltaCallback();
  }
}

Future<int> main() async {
  group('basic', () {
    test('train completes', () async {
      expect(await starter(<String>['--train']), equals(0));
    });
  });

  group('batch compile', () {
    test('compile from command line', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot'
      ];
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        compileCallback: (String filename, ArgResults options) {
          expect(filename, equals('server.dart'));
          expect(options['sdk-root'], equals('sdkroot'));
        }
      ));
      expect(exitcode, equals(0));
    });
  });

  group('interactive compile', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot'
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        compileCallback: (String filename, ArgResults options) {
          expect(filename, equals('server.dart'));
          expect(options['sdk-root'], equals('sdkroot'));
          compileCalled.sendPort.send(true);
        }),
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
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        compileCallback: (String filename, ArgResults options) {
          expect(filename, equals('server${counter++}.dart'));
          expect(options['sdk-root'], equals('sdkroot'));
          compileCalled.sendPort.send(true);
        }),
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('compile server1.dart\n'.codeUnits);
      streamController.add('compile server2.dart\n'.codeUnits);
      await compileCalled.first;
      streamController.close();
    });

    test('recompile few files', () async {
      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      int counter = 0;
      final List<Uri> expectedInvalidatedFiles = <Uri>[
        Uri.base.resolve('file1.dart'),
        Uri.base.resolve('file2.dart'),
      ];
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        invalidateCallback: (Uri uri) {
          expect(uri, equals(expectedInvalidatedFiles[counter++]));
        },
        recompileDeltaCallback: () {
          expect(counter, equals(2));
          recompileCalled.sendPort.send(true);
        }),
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;
      streamController.close();
    });

    test('accept', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort acceptCalled = new ReceivePort();
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        acceptLastDeltaCallback: () {
          acceptCalled.sendPort.send(true);
        }),
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
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        rejectLastDeltaCallback: () {
          rejectCalled.sendPort.send(true);
        }),
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('reject\n'.codeUnits);
      await rejectCalled.first;
      inputStreamController.close();
    });

    test('recompile few files', () async {
      final StreamController<List<int>> streamController =
      new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      int counter = 0;
      final List<Uri> expectedInvalidatedFiles = <Uri>[
        Uri.base.resolve('file1.dart'),
        Uri.base.resolve('file2.dart'),
        Uri.base.resolve('file2.dart'),
        Uri.base.resolve('file3.dart'),
      ];
      bool acceptCalled = false;
      final int exitcode = await starter(args, compiler: new _MockedCompiler(
        invalidateCallback: (Uri uri) {
          expect(uri, equals(expectedInvalidatedFiles[counter++]));
        },
        recompileDeltaCallback: () {
          if (counter == 2) {
            expect(acceptCalled, equals(false));
          } else {
            expect(counter, equals(4));
            expect(acceptCalled, equals(true));
          }
          recompileCalled.sendPort.send(true);
        },
        acceptLastDeltaCallback: () {
          expect(acceptCalled, equals(false));
          acceptCalled = true;
        }),
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      streamController.add('accept\n'.codeUnits);
      streamController.add('recompile def\nfile2.dart\nfile3.dart\ndef\n'.codeUnits);
      await recompileCalled.first;
      streamController.close();
    });
  });
  return 0;
}
