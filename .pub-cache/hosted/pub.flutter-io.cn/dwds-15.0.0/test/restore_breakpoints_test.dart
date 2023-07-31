// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:async';

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';
import 'fixtures/logging.dart';

final context = TestContext();
ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);
WipConnection get tabConnection => context.tabConnection;

void main() {
  setUpAll(() async {
    setCurrentLogWriter();
    await context.setUp(
      restoreBreakpoints: true,
    );
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  group('breakpoints', () {
    VM vm;
    Isolate isolate;
    ScriptList scripts;
    ScriptRef mainScript;
    Stream<Event> isolateEventStream;

    setUp(() async {
      setCurrentLogWriter();
      vm = await fetchChromeProxyService(context.debugConnection).getVM();
      isolate = await fetchChromeProxyService(context.debugConnection)
          .getIsolate(vm.isolates.first.id);
      scripts = await fetchChromeProxyService(context.debugConnection)
          .getScripts(isolate.id);
      mainScript =
          scripts.scripts.firstWhere((each) => each.uri.contains('main.dart'));
      isolateEventStream = service.onEvent('Isolate');
    });

    tearDown(() async {
      // Remove breakpoints so they don't impact other tests.
      for (var breakpoint in isolate.breakpoints.toList()) {
        await service.removeBreakpoint(isolate.id, breakpoint.id);
      }
    });

    test('restore after refresh', () async {
      final firstBp =
          await service.addBreakpoint(isolate.id, mainScript.id, 23);
      expect(firstBp, isNotNull);
      expect(firstBp.id, isNotNull);

      final eventsDone = expectLater(
          isolateEventStream,
          emitsThrough(emitsInOrder([
            predicate((Event event) => event.kind == EventKind.kIsolateExit),
            predicate((Event event) => event.kind == EventKind.kIsolateStart),
            predicate(
                (Event event) => event.kind == EventKind.kIsolateRunnable),
          ])));

      await context.webDriver.refresh();
      await eventsDone;

      vm = await service.getVM();
      isolate = await service.getIsolate(vm.isolates.first.id);

      expect(isolate.breakpoints.length, equals(1));
    }, timeout: const Timeout.factor(2));

    test('restore after hot restart', () async {
      final firstBp =
          await service.addBreakpoint(isolate.id, mainScript.id, 23);
      expect(firstBp, isNotNull);
      expect(firstBp.id, isNotNull);

      final eventsDone = expectLater(
          isolateEventStream,
          emits(emitsInOrder([
            predicate((Event event) => event.kind == EventKind.kIsolateExit),
            predicate((Event event) => event.kind == EventKind.kIsolateStart),
            predicate(
                (Event event) => event.kind == EventKind.kIsolateRunnable),
          ])));

      await context.debugConnection.vmService
          .callServiceExtension('hotRestart');
      await eventsDone;

      vm = await service.getVM();
      isolate = await service.getIsolate(vm.isolates.first.id);

      expect(isolate.breakpoints.length, equals(1));
    }, timeout: const Timeout.factor(2));
  });
}
