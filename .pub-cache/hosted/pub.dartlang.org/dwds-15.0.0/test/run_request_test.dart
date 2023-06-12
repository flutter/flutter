// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@Timeout(Duration(minutes: 2))
import 'dart:async';

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'fixtures/context.dart';

final context = TestContext();

ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);

void main() {
  group('while debugger is attached', () {
    setUp(() async {
      await context.setUp(autoRun: false);
    });

    tearDown(() async {
      await context.tearDown();
    });

    test('can resume while paused at the start', () async {
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates.first.id);
      expect(isolate.pauseEvent.kind, EventKind.kPauseStart);
      final stream = service.onEvent('Debug');
      final resumeCompleter = Completer();
      // The underlying stream is a broadcast stream so we need to add a
      // listener before calling resume so that we don't miss events.
      unawaited(stream
          .firstWhere((event) => event.kind == EventKind.kResume)
          .then((_) {
        resumeCompleter.complete();
      }));
      await service.resume(isolate.id);
      await resumeCompleter.future;
      expect(isolate.pauseEvent.kind, EventKind.kResume);
    });

    test('correctly sets the isolate pauseEvent', () async {
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates.first.id);
      expect(isolate.pauseEvent.kind, EventKind.kPauseStart);
      final stream = service.onEvent('Debug');
      context.appConnection.runMain();
      await stream.firstWhere((event) => event.kind == EventKind.kResume);
      expect(isolate.pauseEvent.kind, EventKind.kResume);
    });
  });

  group('while debugger is not attached', () {
    setUp(() async {
      await context.setUp(autoRun: false, waitToDebug: true);
    });

    tearDown(() async {
      await context.tearDown();
    });
    test('correctly sets the isolate pauseEvent if already running', () async {
      context.appConnection.runMain();
      await context.startDebugging();
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates.first.id);
      expect(isolate.pauseEvent.kind, EventKind.kResume);
    });
  });
}
