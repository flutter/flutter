// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Tests that require a fresh context to run, and can interfere with other
/// tests.
@TestOn('vm')
library refresh_test;

import 'dart:async';

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';

final context = TestContext();
ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);
WipConnection get tabConnection => context.tabConnection;

void main() {
  group('fresh context', () {
    VM vm;
    setUpAll(() async {
      await context.setUp();
      vm = await service.getVM();
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    test('can add and remove after a refresh', () async {
      final stream = service.onEvent('Isolate');
      // Wait for the page to be fully loaded before refreshing.
      await Future.delayed(const Duration(seconds: 1));
      // Now wait for the shutdown event.
      final exitEvent =
          stream.firstWhere((e) => e.kind != EventKind.kIsolateExit);
      await context.webDriver.refresh();
      await exitEvent;
      // Wait for the refresh to propagate through.
      final isolateStart =
          await stream.firstWhere((e) => e.kind != EventKind.kIsolateStart);
      final isolateId = isolateStart.isolate.id;
      final refreshedScriptList = await service.getScripts(isolateId);
      final refreshedMain = refreshedScriptList.scripts
          .lastWhere((each) => each.uri.contains('main.dart'));
      final bpLine = await context.findBreakpointLine(
          'printHelloWorld', isolateId, refreshedMain);
      final bp =
          await service.addBreakpoint(isolateId, refreshedMain.id, bpLine);
      final isolate = await service.getIsolate(vm.isolates.first.id);
      expect(isolate.breakpoints, [bp]);
      expect(bp.id, isNotNull);
      await service.removeBreakpoint(isolateId, bp.id);
      expect(isolate.breakpoints, isEmpty);
    });
  });
}
