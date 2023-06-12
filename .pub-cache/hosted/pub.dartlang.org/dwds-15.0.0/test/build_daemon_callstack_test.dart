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

class TestSetup {
  static final contextUnsound = TestContext(
      directory: p.join('..', 'fixtures', '_testPackage'),
      entry: p.join('..', 'fixtures', '_testPackage', 'web', 'main.dart'),
      path: 'index.html',
      pathToServe: 'web');

  static final contextSound = TestContext(
      directory: p.join('..', 'fixtures', '_testPackageSound'),
      entry: p.join('..', 'fixtures', '_testPackageSound', 'web', 'main.dart'),
      path: 'index.html',
      pathToServe: 'web');

  TestContext context;

  TestSetup.sound() : context = contextSound;

  TestSetup.unsound() : context = contextUnsound;

  ChromeProxyService get service =>
      fetchChromeProxyService(context.debugConnection);
  WipConnection get tabConnection => context.tabConnection;
}

void main() {
  group('shared context |', () {
    // Enable verbose logging for debugging.
    final debug = false;

    for (var nullSafety in NullSafety.values) {
      final soundNullSafety = nullSafety == NullSafety.sound;
      final setup = soundNullSafety ? TestSetup.sound() : TestSetup.unsound();
      final context = setup.context;

      group('${nullSafety.name} null safety |', () {
        setUpAll(() async {
          setCurrentLogWriter(debug: debug);
          await context.setUp(
            compilationMode: CompilationMode.buildDaemon,
            nullSafety: nullSafety,
            enableExpressionEvaluation: true,
            verboseCompiler: debug,
          );
        });

        tearDownAll(() async {
          await context.tearDown();
        });

        group('callStack |', () {
          ChromeProxyService service;
          VM vm;
          Isolate isolate;
          ScriptList scripts;
          ScriptRef mainScript;
          ScriptRef testLibraryScript;
          Stream<Event> stream;

          setUp(() async {
            setCurrentLogWriter(debug: debug);
            service = setup.service;
            vm = await service.getVM();
            isolate = await service.getIsolate(vm.isolates.first.id);
            scripts = await service.getScripts(isolate.id);

            await service.streamListen('Debug');
            stream = service.onEvent('Debug');

            final testPackage =
                soundNullSafety ? '_test_package_sound' : '_test_package';

            mainScript = scripts.scripts
                .firstWhere((each) => each.uri.contains('main.dart'));
            testLibraryScript = scripts.scripts.firstWhere((each) =>
                each.uri.contains('package:$testPackage/test_library.dart'));
          });

          tearDown(() async {
            await service.resume(isolate.id);
          });

          Future<void> onBreakPoint(BreakpointTestData breakpoint,
              Future<void> Function() body) async {
            Breakpoint bp;
            try {
              final bpId = breakpoint.bpId;
              final script = breakpoint.script;
              final line =
                  await context.findBreakpointLine(bpId, isolate.id, script);
              bp = await setup.service
                  .addBreakpointWithScriptUri(isolate.id, script.uri, line);

              expect(bp, isNotNull);
              expect(bp.location, _matchBpLocation(script, line, 0));

              await stream.firstWhere(
                  (Event event) => event.kind == EventKind.kPauseBreakpoint);

              await body();
            } finally {
              // Remove breakpoint so it doesn't impact other tests or retries.
              if (bp != null) {
                await setup.service.removeBreakpoint(isolate.id, bp.id);
              }
            }
          }

          Future<void> testCallStack(List<BreakpointTestData> breakpoints,
              {int frameIndex = 1}) async {
            // Find lines the breakpoints are located on.
            final lines = await Future.wait(breakpoints.map((frame) => context
                .findBreakpointLine(frame.bpId, isolate.id, frame.script)));

            // Get current stack.
            final stack = await service.getStack(isolate.id);

            // Verify the stack is correct.
            expect(stack.frames.length, greaterThanOrEqualTo(lines.length));
            final expected = [
              for (var i = 0; i < lines.length; i++)
                _matchFrame(
                    breakpoints[i].script, breakpoints[i].function, lines[i])
            ];
            expect(stack.frames, containsAll(expected));

            // Verify that expression evaluation is not failing.
            final instance =
                await service.evaluateInFrame(isolate.id, frameIndex, 'true');
            expect(instance, isA<InstanceRef>());
          }

          test('breakpoint succeeds with correct callstack', () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'printEnclosingObject',
                'printEnclosingObject',
                mainScript,
              ),
              BreakpointTestData(
                'printEnclosingFunctionMultiLine',
                'printNestedObjectsMultiLine',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintEnclosingFunctionMultiLine',
                '<closure>',
                mainScript,
              ),
            ];
            await onBreakPoint(
                breakpoints[0], () => testCallStack(breakpoints));
          });

          test('expression evaluation succeeds on parent frame', () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'testLibraryClassConstructor',
                'new',
                testLibraryScript,
              ),
              BreakpointTestData(
                'createLibraryObject',
                'printFieldFromLibraryClass',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintFieldFromLibraryClass',
                '<closure>',
                mainScript,
              ),
            ];
            await onBreakPoint(breakpoints[0],
                () => testCallStack(breakpoints, frameIndex: 2));
          });

          test('breakpoint inside a line gives correct callstack', () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'newEnclosedClass',
                'new',
                mainScript,
              ),
              BreakpointTestData(
                'printNestedObjectMultiLine',
                'printNestedObjectsMultiLine',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintEnclosingFunctionMultiLine',
                '<closure>',
                mainScript,
              ),
            ];
            await onBreakPoint(
                breakpoints[0], () => testCallStack(breakpoints));
          });

          test('breakpoint gives correct callstack after step out', () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'newEnclosedClass',
                'new',
                mainScript,
              ),
              BreakpointTestData(
                'printEnclosingObjectMultiLine',
                'printNestedObjectsMultiLine',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintEnclosingFunctionMultiLine',
                '<closure>',
                mainScript,
              ),
            ];
            await onBreakPoint(breakpoints[0], () async {
              await service.resume(isolate.id, step: 'Out');
              await stream.firstWhere(
                  (Event event) => event.kind == EventKind.kPauseInterrupted);
              return testCallStack([breakpoints[1], breakpoints[2]]);
            });
          });

          test('breakpoint gives correct callstack after step in', () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'newEnclosedClass',
                'new',
                mainScript,
              ),
              BreakpointTestData(
                'printNestedObjectMultiLine',
                'printNestedObjectsMultiLine',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintEnclosingFunctionMultiLine',
                '<closure>',
                mainScript,
              ),
            ];
            await onBreakPoint(breakpoints[1], () async {
              await service.resume(isolate.id, step: 'Into');
              await stream.firstWhere(
                  (Event event) => event.kind == EventKind.kPauseInterrupted);
              return testCallStack(breakpoints);
            });
          });

          test('breakpoint gives correct callstack after step into chain calls',
              () async {
            // Expected breakpoints on the stack
            final breakpoints = [
              BreakpointTestData(
                'createObjectWithMethod',
                'createObject',
                mainScript,
              ),
              BreakpointTestData(
                // This is currently incorrect, should be printObjectMultiLine.
                // See issue: https://github.com/dart-lang/sdk/issues/48874
                'printMultiLine',
                'printObjectMultiLine',
                mainScript,
              ),
              BreakpointTestData(
                'callPrintObjectMultiLine',
                '<closure>',
                mainScript,
              ),
            ];
            final bp = BreakpointTestData(
                'printMultiLine', 'printObjectMultiLine', mainScript);
            await onBreakPoint(bp, () async {
              await service.resume(isolate.id, step: 'Into');
              await stream.firstWhere(
                  (Event event) => event.kind == EventKind.kPauseInterrupted);
              return testCallStack(breakpoints);
            });
          });
        });
      });
    }
  });
}

Matcher _matchFrame(ScriptRef script, String function, int line) => isA<Frame>()
    .having((frame) => frame.code.name, 'function', function)
    .having((frame) => frame.location, 'location',
        _matchFrameLocation(script, line));

Matcher _matchBpLocation(ScriptRef script, int line, int column) =>
    isA<SourceLocation>()
        .having((loc) => loc.script, 'script', equals(script))
        .having((loc) => loc.line, 'line', equals(line))
        .having((loc) => loc.column, 'column', greaterThanOrEqualTo(column));

Matcher _matchFrameLocation(ScriptRef script, int line) => isA<SourceLocation>()
    .having((loc) => loc.script, 'script', equals(script))
    .having((loc) => loc.line, 'line', equals(line));

class BreakpointTestData {
  String bpId;
  String function;
  ScriptRef script;

  BreakpointTestData(this.bpId, this.function, this.script);
}
