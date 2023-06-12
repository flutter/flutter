// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:async';

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';

final context = TestContext(
    directory: p.join('..', 'fixtures', '_testPackage'),
    entry: p.join('..', 'fixtures', '_testPackage', 'web', 'main.dart'),
    path: 'index.html',
    pathToServe: 'web');

ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);
WipConnection get tabConnection => context.tabConnection;

void main() {
  group('shared context', () {
    setUpAll(() async {
      await context.setUp();
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    group('breakpoint', () {
      VM vm;
      Isolate isolate;
      ScriptList scripts;
      ScriptRef mainScript;
      Stream<Event> stream;

      setUp(() async {
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates.first.id);
        scripts = await service.getScripts(isolate.id);

        await service.streamListen('Debug');
        stream = service.onEvent('Debug');

        mainScript = scripts.scripts
            .firstWhere((each) => each.uri.contains('main.dart'));
      });

      tearDown(() async {
        await service.resume(isolate.id);
      });

      test('set breakpoint', () async {
        final line = await context.findBreakpointLine(
            'printLocal', isolate.id, mainScript);
        final bp = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        expect(bp, isNotNull);

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id, bp.id);
      });

      test('set breakpoint again', () async {
        final line = await context.findBreakpointLine(
            'printLocal', isolate.id, mainScript);
        final bp = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        expect(bp, isNotNull);

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id, bp.id);
      });

      test('set existing breakpoint succeeds', () async {
        final line = await context.findBreakpointLine(
            'printLocal', isolate.id, mainScript);
        final bp1 = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line);
        final bp2 = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line);

        expect(bp1, equals(bp2));
        expect(bp1, isNotNull);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        var currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, containsAll([bp1]));

        // Remove breakpoints so they don't impact other tests.
        await service.removeBreakpoint(isolate.id, bp1.id);

        currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, isEmpty);
      });

      test('set breakpoints at the same line simultaneously succeeds',
          () async {
        final line = await context.findBreakpointLine(
            'printLocal', isolate.id, mainScript);
        final futures = [
          service.addBreakpointWithScriptUri(isolate.id, mainScript.uri, line),
          service.addBreakpointWithScriptUri(isolate.id, mainScript.uri, line),
        ];

        final breakpoints = await Future.wait(futures);
        expect(breakpoints[0], equals(breakpoints[1]));
        expect(breakpoints[0], isNotNull);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        var currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, containsAll([breakpoints[0]]));

        // Remove breakpoints so they don't impact other tests.
        await service.removeBreakpoint(isolate.id, breakpoints[0].id);

        currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, isEmpty);
      });

      test('remove non-existing breakpoint fails', () async {
        final line = await context.findBreakpointLine(
            'printLocal', isolate.id, mainScript);
        final bp = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        var currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, containsAll([bp]));

        // Remove breakpoints so they don't impact other tests.
        await service.removeBreakpoint(isolate.id, bp.id);
        await expectLater(
            service.removeBreakpoint(isolate.id, bp.id), throwsRPCError);

        currentIsolate = await service.getIsolate(isolate.id);
        expect(currentIsolate.breakpoints, isEmpty);
      });
    });
  });
}
