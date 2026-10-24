// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_tools/src/base/exit.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  group('Signals', () {
    late Signals signals;
    late FakeProcessSignal fakeSignal;
    late ProcessSignal signalUnderTest;
    late FakeShutdownHooks shutdownHooks;

    setUp(() {
      shutdownHooks = FakeShutdownHooks();
      signals = Signals.test(shutdownHooks: shutdownHooks);
      fakeSignal = FakeProcessSignal();
      signalUnderTest = ProcessSignal(fakeSignal);
    });

    testWithoutContext('signal handler runs', () async {
      final completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
    });

    testWithoutContext('signal handlers run in order', () async {
      final completer = Completer<void>();

      var first = false;

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        first = true;
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        expect(first, isTrue);
        completer.complete();
      });

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
    });

    testWithoutContext('signal handlers do not cause concurrent modification errors when removing handlers in a signal callback', () async {
      final completer = Completer<void>();
      late Object token;
      Future<void> handle(ProcessSignal s) async {
        expect(s, signalUnderTest);
        expect(await signals.removeHandler(signalUnderTest, token), true);
        completer.complete();
      }

      token = signals.addHandler(signalUnderTest, handle);

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
    });

    testWithoutContext('signal handler error goes on error stream', () async {
      final exn = Exception('Error');
      signals.addHandler(signalUnderTest, (ProcessSignal s) async {
        throw exn;
      });

      final completer = Completer<void>();
      final errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen((Object err) {
        errList.add(err);
        completer.complete();
      });

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, contains(exn));
    });

    testWithoutContext('removed signal handler does not run', () async {
      final Object token = signals.addHandler(signalUnderTest, (ProcessSignal s) async {
        fail('Signal handler should have been removed.');
      });

      await signals.removeHandler(signalUnderTest, token);

      final errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen((Object err) {
        errList.add(err);
      });

      fakeSignal.controller.add(fakeSignal);

      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('non-removed signal handler still runs', () async {
      final completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      final Object token = signals.addHandler(signalUnderTest, (ProcessSignal s) async {
        fail('Signal handler should have been removed.');
      });
      await signals.removeHandler(signalUnderTest, token);

      final errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen((Object err) {
        errList.add(err);
      });

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('only handlers for the correct signal run', () async {
      final mockSignal2 = FakeProcessSignal();
      final otherSignal = ProcessSignal(mockSignal2);

      final completer = Completer<void>();
      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        expect(s, signalUnderTest);
        completer.complete();
      });

      signals.addHandler(otherSignal, (ProcessSignal s) async {
        fail('Wrong signal!.');
      });

      final errList = <Object>[];
      final StreamSubscription<Object> errSub = signals.errors.listen((Object err) {
        errList.add(err);
      });

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      await errSub.cancel();
      expect(errList, isEmpty);
    });

    testWithoutContext('all handlers for exiting signals are run before exit', () async {
      final signals = Signals.test(
        analytics: const NoOpAnalytics(),
        exitSignals: <ProcessSignal>[signalUnderTest],
        logger: BufferLogger.test(),
        shutdownHooks: shutdownHooks,
      );
      final completer = Completer<void>();
      var first = false;
      var second = false;

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

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      expect(shutdownHooks.isShuttingDown, isTrue);
    });

    testWithoutContext('ShutdownHooks run before exiting', () async {
      final signals = Signals.test(
        analytics: const NoOpAnalytics(),
        exitSignals: <ProcessSignal>[signalUnderTest],
        logger: BufferLogger.test(),
        shutdownHooks: shutdownHooks,
      );
      final completer = Completer<void>();

      setExitFunctionForTests((int exitCode) {
        expect(exitCode, 0);
        restoreExitFunction();
        completer.complete();
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {});

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      expect(shutdownHooks.isShuttingDown, isTrue);
    });

    testWithoutContext('unconfigured Signals.test exits cleanly on exiting signal', () async {
      final signals = Signals.test(
        exitSignals: <ProcessSignal>[signalUnderTest],
        shutdownHooks: shutdownHooks,
      );
      final completer = Completer<void>();

      setExitFunctionForTests((int exitCode) {
        expect(exitCode, 0);
        restoreExitFunction();
        completer.complete();
      });

      signals.addHandler(signalUnderTest, (ProcessSignal s) {});

      fakeSignal.controller.add(fakeSignal);
      await completer.future;
      expect(shutdownHooks.isShuttingDown, isFalse);
    });

    testWithoutContext(
      'configured Signals.test logs analytics consent and closes analytics',
      () async {
        final analytics = FakeAnalytics();
        final logger = BufferLogger.test();
        final signals = Signals.test(
          analytics: analytics,
          exitSignals: <ProcessSignal>[signalUnderTest],
          logger: logger,
          shutdownHooks: shutdownHooks,
        );
        final completer = Completer<void>();

        setExitFunctionForTests((int exitCode) {
          expect(exitCode, 0);
          restoreExitFunction();
          completer.complete();
        });

        signals.addHandler(signalUnderTest, (ProcessSignal s) {});

        fakeSignal.controller.add(fakeSignal);
        await completer.future;
        expect(shutdownHooks.isShuttingDown, isTrue);
        expect(logger.statusText, contains('fake consent message'));
        expect(analytics.didShowMessage, isTrue);
        expect(analytics.didClose, isTrue);
      },
    );
  });
}

class FakeAnalytics extends Fake implements Analytics {
  bool didShowMessage = false;
  bool didClose = false;

  @override
  bool get shouldShowMessage => true;

  @override
  String get getConsentMessage => 'fake consent message';

  @override
  void clientShowedMessage() {
    didShowMessage = true;
  }

  @override
  Future<void> close({int delayDuration = 0}) async {
    didClose = true;
  }
}

class FakeProcessSignal extends Fake implements io.ProcessSignal {
  final controller = StreamController<io.ProcessSignal>();

  @override
  Stream<io.ProcessSignal> watch() => controller.stream;
}
