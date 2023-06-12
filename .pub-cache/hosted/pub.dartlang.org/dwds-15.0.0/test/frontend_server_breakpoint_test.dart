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
import 'fixtures/logging.dart';

final context = TestContext(
    directory: p.join('..', 'fixtures', '_testPackage'),
    entry: p.join('..', 'fixtures', '_testPackage', 'web', 'main.dart'),
    path: 'index.html',
    pathToServe: 'web');

ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);
WipConnection get tabConnection => context.tabConnection;

void main() {
  // Enable verbose logging for debugging.
  final debug = false;

  // Change to 'true' to print expression compiler messages to console.
  //
  // Note: expression compiler runs in an isolate, so its output is not
  // currently redirected to a logger. As a result, it will be printed
  // regardless of the logger settings.
  final verboseCompiler = false;

  group('shared context', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: debug);
      await context.setUp(
        compilationMode: CompilationMode.frontendServer,
        verboseCompiler: verboseCompiler,
      );
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
        setCurrentLogWriter(debug: debug);
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

      test('set breakpoint inside a JavaScript line succeeds', () async {
        final line = await context.findBreakpointLine(
            'printNestedObjectMultiLine', isolate.id, mainScript);
        final column = 0;
        final bp = await service.addBreakpointWithScriptUri(
            isolate.id, mainScript.uri, line,
            column: column);

        await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint);

        expect(bp, isNotNull);
        expect(
            bp.location,
            isA<SourceLocation>()
                .having((loc) => loc.script, 'script', equals(mainScript))
                .having((loc) => loc.line, 'line', equals(line))
                .having((loc) => loc.column, 'column', greaterThan(column)));

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id, bp.id);
      });
    });
  });
}
