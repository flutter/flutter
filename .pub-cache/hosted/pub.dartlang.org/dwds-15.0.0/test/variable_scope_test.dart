// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/debugging/dart_scope.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';

final context = TestContext(
    directory: '../example', path: 'scopes.html', pathToServe: 'web');
ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);
WipConnection get tabConnection => context.tabConnection;

void main() {
  setUpAll(() async {
    await context.setUp();
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  group('ddcTemporaryVariableRegExp', () {
    test('matches correctly', () {
      expect(ddcTemporaryVariableRegExp.hasMatch(r't4$'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't4$0'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't4$10'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't4$0'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't1'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't10'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'__t$TL'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'__t$StringN'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'__t$IdentityMapOfString$T'),
          isTrue);

      expect(ddcTemporaryVariableRegExp.hasMatch(r't'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't10foo'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$10foo'), isFalse);
    });
  });

  group('variable scope', () {
    VM vm;
    String isolateId;
    Stream<Event> stream;
    ScriptList scripts;
    ScriptRef mainScript;
    Stack stack;

    // TODO: Be able to set breakpoints before start/reload so we can exercise
    // things that aren't in recurring loops.

    /// Support function for pausing and returning the stack at a line.
    Future<Stack> breakAt(String breakpointId, ScriptRef scriptRef) async {
      final lineNumber =
          await context.findBreakpointLine(breakpointId, isolateId, scriptRef);

      final bp =
          await service.addBreakpoint(isolateId, scriptRef.id, lineNumber);
      // Wait for breakpoint to trigger.
      await stream
          .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);
      // Remove breakpoint so it doesn't impact other tests.
      await service.removeBreakpoint(isolateId, bp.id);
      final stack = await service.getStack(isolateId);
      return stack;
    }

    Future<Instance> getInstance(InstanceRef ref) async {
      final result = await service.getObject(isolateId, ref.id);
      expect(result, isA<Instance>());
      return result as Instance;
    }

    void expectDartObject(String variableName, Instance instance) {
      expect(
          instance,
          isA<Instance>().having(
              (instance) => instance.classRef.name,
              '$variableName: classRef.name',
              isNot(isIn([
                'NativeJavaScriptObject',
                'JavaScriptObject',
              ]))));
    }

    Future<void> expectDartVariables(Map<String, InstanceRef> variables) async {
      for (var name in variables.keys) {
        final instance = await getInstance(variables[name]);
        expectDartObject(name, instance);
      }
    }

    Map<String, InstanceRef> getFrameVariables(Frame frame) {
      return <String, InstanceRef>{
        for (var variable in frame.vars)
          variable.name: variable.value as InstanceRef,
      };
    }

    setUp(() async {
      vm = await service.getVM();
      isolateId = vm.isolates.first.id;
      scripts = await service.getScripts(isolateId);
      await service.streamListen('Debug');
      stream = service.onEvent('Debug');
      mainScript = scripts.scripts
          .firstWhere((each) => each.uri.contains('scopes_main.dart'));
    });

    tearDown(() async {
      await service.resume(isolateId);
    });

    test('variables in static function', () async {
      stack = await breakAt('staticFunction', mainScript);
      final variables = getFrameVariables(stack.frames.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames, containsAll(['formal']));
    });

    test('variables in function', () async {
      stack = await breakAt('nestedFunction', mainScript);
      final variables = getFrameVariables(stack.frames.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(
          variableNames,
          containsAll([
            'aClass',
            'another',
            'intLocalInMain',
            'local',
            'localThatsNull',
            'nestedFunction',
            'parameter',
            'testClass'
          ]));
    });

    test('variables in closure nested in method', () async {
      stack = await breakAt('nestedClosure', mainScript);
      final variables = getFrameVariables(stack.frames.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames,
          ['closureLocalInsideMethod', 'local', 'parameter', 'this']);
    });

    test('variables in method', () async {
      stack = await breakAt('printMethod', mainScript);
      final variables = getFrameVariables(stack.frames.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames, ['this']);
    });

    test('variables in extension method', () async {
      stack = await breakAt('extension', mainScript);
      final variables = getFrameVariables(stack.frames.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      // Note: '$this' should change to 'this', and 'return' should
      // disappear after debug symbols are available.
      // https://github.com/dart-lang/webdev/issues/1371
      expect(variableNames, ['\$this', 'ret', 'return']);
    });

    test('evaluateJsOnCallFrame', () async {
      stack = await breakAt('nestedFunction', mainScript);
      final inspector = service.appInspectorProvider();
      final debugger = inspector.debugger;
      final parameter =
          await debugger.evaluateJsOnCallFrameIndex(0, 'parameter');
      expect(parameter.value, matches(RegExp(r'\d+ world')));
      final ticks = await debugger.evaluateJsOnCallFrameIndex(1, 'ticks');
      // We don't know how many ticks there were before we stopped, but it should
      // be a positive number.
      expect(ticks.value, isPositive);
    });
  });
}
