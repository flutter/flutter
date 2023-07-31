// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:process/process.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessWrapper', () {
    late TestProcess delegate;
    late ProcessWrapper process;

    setUp(() {
      delegate = TestProcess();
      process = ProcessWrapper(delegate);
    });

    group('done', () {
      late bool done;

      setUp(() {
        done = false;
        // ignore: unawaited_futures
        process.done.then((int result) {
          done = true;
        });
      });

      test('completes only when all done', () async {
        expect(done, isFalse);
        delegate.exitCodeCompleter.complete(0);
        await Future<void>.value();
        expect(done, isFalse);
        await delegate.stdoutController.close();
        await Future<void>.value();
        expect(done, isFalse);
        await delegate.stderrController.close();
        await Future<void>.value();
        expect(done, isTrue);
        expect(await process.exitCode, 0);
      });

      test('works in conjunction with subscribers to stdio streams', () async {
        process.stdout
            .transform<String>(utf8.decoder)
            .transform<String>(const LineSplitter())
            .listen(print);
        delegate.exitCodeCompleter.complete(0);
        await delegate.stdoutController.close();
        await delegate.stderrController.close();
        await Future<void>.value();
        expect(done, isTrue);
      });
    });

    group('stdio', () {
      test('streams properly close', () async {
        Future<void> testStream(
          Stream<List<int>> stream,
          StreamController<List<int>> controller,
          String name,
        ) async {
          bool closed = false;
          stream.listen(
            (_) {},
            onDone: () {
              closed = true;
            },
          );
          await controller.close();
          await Future<void>.value();
          expect(closed, isTrue, reason: 'for $name');
        }

        await testStream(process.stdout, delegate.stdoutController, 'stdout');
        await testStream(process.stderr, delegate.stderrController, 'stderr');
      });
    });
  });
}

class TestProcess implements io.Process {
  TestProcess([this.pid = 123])
      : exitCodeCompleter = Completer<int>(),
        stdoutController = StreamController<List<int>>(),
        stderrController = StreamController<List<int>>();

  @override
  final int pid;
  final Completer<int> exitCodeCompleter;
  final StreamController<List<int>> stdoutController;
  final StreamController<List<int>> stderrController;

  @override
  Future<int> get exitCode => exitCodeCompleter.future;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    exitCodeCompleter.complete(-1);
    return true;
  }

  @override
  Stream<List<int>> get stderr => stderrController.stream;

  @override
  io.IOSink get stdin => throw UnsupportedError('Not supported');

  @override
  Stream<List<int>> get stdout => stdoutController.stream;
}
