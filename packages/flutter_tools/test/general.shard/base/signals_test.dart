// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  group('Signals', () {
    Signals signals;
    MockIoProcessSignal mockSignal;
    ProcessSignal signalUnderTest;
    StreamController<io.ProcessSignal> controller;

    setUp(() {
      signals = Signals.test();
      mockSignal = MockIoProcessSignal();
      signalUnderTest = ProcessSignal(mockSignal);
      controller = StreamController<io.ProcessSignal>();
      when(mockSignal.watch()).thenAnswer((Invocation invocation) => controller.stream);
    });

    testWithoutContext('signal handler runs', () async {
      final Completer<void> completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      controller.add(mockSignal);
      await completer.future;
    });

    testWithoutContext('signal handlers run in order', () async {
      final Completer<void> completer = Completer<void>();

      bool first = false;

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        first = true;
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        expect(first, isTrue);
        completer.complete();
      });

      controller.add(mockSignal);
      await completer.future;
    });

    testWithoutContext('signal handler error goes on error stream', () async {
      final Exception exn = Exception('Error');
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        throw exn;
      });

      final Completer<void> completer = Completer<void>();
      final List<Object> errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen(
        (Object err) {
          errList.add(err);
          completer.complete();
        },
      );

      controller.add(mockSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, contains(exn));
    });

    testWithoutContext('removed signal handler does not run', () async {
      final Object token = signals.addHandler(
        signalUnderTest,
        (ProcessSignal s) {
          fail('Signal handler should have been removed.');
        },
      );

      await signals.removeHandler(signalUnderTest, token);

      final List<Object> errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen(
        (Object err) {
          errList.add(err);
        },
      );

      controller.add(mockSignal);

      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('non-removed signal handler still runs', () async {
      final Completer<void> completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      final Object token = signals.addHandler(
        signalUnderTest,
        (ProcessSignal s) {
          fail('Signal handler should have been removed.');
        },
      );
      await signals.removeHandler(signalUnderTest, token);

      final List<Object> errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen(
        (Object err) {
          errList.add(err);
        },
      );

      controller.add(mockSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('only handlers for the correct signal run', () async {
      final MockIoProcessSignal mockSignal2 = MockIoProcessSignal();
      final StreamController<io.ProcessSignal> controller2 = StreamController<io.ProcessSignal>();
      final ProcessSignal otherSignal = ProcessSignal(mockSignal2);

      when(mockSignal2.watch()).thenAnswer((Invocation invocation) => controller2.stream);

      final Completer<void> completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      signals.addHandler(otherSignal, (ProcessSignal s) {
        fail('Wrong signal!.');
      });

      final List<Object> errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen(
        (Object err) {
          errList.add(err);
        },
      );

      controller.add(mockSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('all handlers for exiting signals are run before exit', () async {
      final Signals signals = Signals.test(
        exitSignals: <ProcessSignal>[signalUnderTest],
      );
      final Completer<void> completer = Completer<void>();
      bool first = false;
      bool second = false;

      setExitFunctionForTests((int exitCode) {
        // Both handlers have run before exit is called.
        expect(first, isTrue);
        expect(second, isTrue);
        expect(exitCode, 0);
        restoreExitFunction();
        completer.complete();
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        expect(first, isFalse);
        expect(second, isFalse);
        first = true;
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        expect(first, isTrue);
        expect(second, isFalse);
        second = true;
      });

      controller.add(mockSignal);
      await completer.future;
    });
  });
}

class MockIoProcessSignal extends Mock implements io.ProcessSignal {}
