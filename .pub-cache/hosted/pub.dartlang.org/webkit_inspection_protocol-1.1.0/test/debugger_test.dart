// Copyright 2020 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library wip.debugger_test;

import 'dart:async';

import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'test_setup.dart';

void main() {
  group('WipDebugger', () {
    WipDebugger? debugger;
    List<StreamSubscription> subs = [];

    setUp(() async {
      debugger = (await wipConnection).debugger;
    });

    tearDown(() async {
      await debugger?.disable();
      debugger = null;

      await closeConnection();
      for (var s in subs) {
        s.cancel();
      }
      subs.clear();
    });

    test('gets script events', () async {
      final controller = StreamController<ScriptParsedEvent>();
      subs.add(debugger!.onScriptParsed.listen(controller.add));

      await debugger!.enable();
      await navigateToPage('debugger_test.html');

      expect(controller.stream.first, isNotNull);
    });

    test('getScriptSource', () async {
      final controller = StreamController<ScriptParsedEvent>();
      subs.add(debugger!.onScriptParsed.listen(controller.add));

      await debugger!.enable();
      await navigateToPage('debugger_test.html');

      final event = await controller.stream
          .firstWhere((event) => event.script.url.endsWith('.html'));
      expect(event.script.scriptId, isNotEmpty);

      final source = await debugger!.getScriptSource(event.script.scriptId);
      expect(source, isNotEmpty);
    });

    test('getPossibleBreakpoints', () async {
      final controller = StreamController<ScriptParsedEvent>();
      subs.add(debugger!.onScriptParsed.listen(controller.add));

      await debugger!.enable();
      await navigateToPage('debugger_test.html');

      final event = await controller.stream
          .firstWhere((event) => event.script.url.endsWith('.html'));
      expect(event.script.scriptId, isNotEmpty);

      final script = event.script;

      final result = await debugger!
          .getPossibleBreakpoints(WipLocation.fromValues(script.scriptId, 0));
      expect(result, isNotEmpty);
      expect(result.any((bp) => bp.lineNumber == 10), true);
    });

    test('setBreakpoint / removeBreakpoint', () async {
      final controller = StreamController<ScriptParsedEvent>();
      subs.add(debugger!.onScriptParsed.listen(controller.add));

      await debugger!.enable();
      await navigateToPage('debugger_test.html');

      final event = await controller.stream
          .firstWhere((event) => event.script.url.endsWith('.html'));
      expect(event.script.scriptId, isNotEmpty);

      final script = event.script;

      final bpResult = await debugger!
          .setBreakpoint(WipLocation.fromValues(script.scriptId, 10));
      expect(bpResult.breakpointId, isNotEmpty);

      final result = await debugger!.removeBreakpoint(bpResult.breakpointId);
      expect(result.result, isEmpty);
    });
  });
}
