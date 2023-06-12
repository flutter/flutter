// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/events.dart';
import 'package:dwds/src/services/chrome_proxy_service.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webdriver/async_core.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';
import 'fixtures/logging.dart';

ChromeProxyService get service =>
    fetchChromeProxyService(context.debugConnection);

WipConnection get tabConnection => context.tabConnection;

final context = TestContext();

void main() {
  group('serve requests', () {
    HttpServer server;

    setUp(() async {
      setCurrentLogWriter();
      server = await startHttpServer('localhost', port: 0);
    });

    tearDown(() async {
      await server?.close();
    });

    test('emits HTTP_REQUEST_EXCEPTION event', () async {
      Future<void> throwAsyncException() async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw Exception('async error');
      }

      // The events stream is a broadcast stream so start listening
      // before the action.
      final events = expectLater(
          pipe(eventStream),
          emitsThrough(matchesEvent(DwdsEventKind.httpRequestException, {
            'server': 'FakeServer',
            'exception': startsWith('Exception: async error'),
          })));

      // Start serving requests with a failing handler in an error zone.
      serveHttpRequests(server, (request) async {
        unawaited(throwAsyncException());
        return null;
      }, (e, s) {
        emitEvent(DwdsEvent.httpRequestException('FakeServer', '$e:$s'));
      });

      // Send a request.
      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('http://localhost:${server.port}/foo'));

      // Ignore the response.
      final response = await request.close();
      await response.drain();

      // Wait for expected events.
      await events;
    });
  });

  group('with dwds', () {
    Future initialEvents;
    VmService vmService;
    Keyboard keyboard;
    Stream<DwdsEvent> events;

    /// Runs [action] and waits for an event matching [eventMatcher].
    Future<T> expectEventDuring<T>(
        Matcher eventMatcher, Future<T> Function() action,
        {Timeout timeout}) async {
      // The events stream is a broadcast stream so start listening
      // before the action.
      final events = expectLater(
          pipe(context.testServer.dwds.events, timeout: timeout),
          emitsThrough(eventMatcher));
      final result = await action();
      await events;
      return result;
    }

    /// Runs [action] and waits for an event matching [eventMatcher].
    Future<T> expectEventsDuring<T>(
        List<Matcher> eventMatchers, Future<T> Function() action,
        {Timeout timeout}) async {
      // The events stream is a broadcast stream so start listening
      // before the action.
      final events = eventMatchers.map((matcher) => expectLater(
          pipe(context.testServer.dwds.events, timeout: timeout),
          emitsThrough(matcher)));
      final result = await action();
      await Future.wait(events);
      return result;
    }

    setUpAll(() async {
      setCurrentLogWriter();
      initialEvents = expectLater(
          pipe(eventStream, timeout: const Timeout.factor(5)),
          emitsThrough(matchesEvent(DwdsEventKind.compilerUpdateDependencies, {
            'entrypoint': 'hello_world/main.dart.bootstrap.js',
            'elapsedMilliseconds': isNotNull
          })));
      await context.setUp(
        serveDevTools: true,
        enableExpressionEvaluation: true,
      );
      vmService = context.debugConnection.vmService;
      keyboard = context.webDriver.driver.keyboard;
      events = context.testServer.dwds.events;
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    test('emits DEBUGGER_READY and DEVTOOLS_LOAD events', () async {
      await expectEventsDuring(
        [
          matchesEvent(DwdsEventKind.debuggerReady, {
            'elapsedMilliseconds': isNotNull,
            'screen': equals('debugger'),
          }),
          matchesEvent(DwdsEventKind.devToolsLoad, {
            'elapsedMilliseconds': isNotNull,
            'screen': equals('debugger'),
          }),
        ],
        () => keyboard.sendChord([Keyboard.alt, 'd']),
      );
    });

    test('emits DEVTOOLS_LAUNCH event', () async {
      await expectEventDuring(
        matchesEvent(DwdsEventKind.devtoolsLaunch, {}),
        () => keyboard.sendChord([Keyboard.alt, 'd']),
      );
    });

    test('events can be listened to multiple times', () async {
      events.listen((_) {});
      events.listen((_) {});
    });

    test('can emit event through service extension', () async {
      final response = await expectEventDuring(
          matchesEvent('foo-event', {'data': 1234}),
          () => vmService.callServiceExtension('ext.dwds.emitEvent', args: {
                'type': 'foo-event',
                'payload': {'data': 1234},
              }));
      expect(response.type, 'Success');
    });

    group('evaluate', () {
      Isolate isolate;
      LibraryRef bootstrap;

      setUpAll(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates.first.id);
        bootstrap = isolate.rootLib;
      });

      setUp(() async {
        setCurrentLogWriter();
      });

      test('emits EVALUATE events on evaluation success', () async {
        final expression = "helloString('world')";
        await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluate, {
              'expression': expression,
              'success': isTrue,
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.evaluate(isolate.id, bootstrap.id, expression));
      });

      test('emits COMPILER_UPDATE_DEPENDENCIES event', () async {
        await initialEvents;
      });

      test('emits EVALUATE events on evaluation failure', () async {
        final expression = 'some-bad-expression';
        await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluate, {
              'expression': expression,
              'success': isFalse,
              'error': isA<ErrorRef>(),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.evaluate(isolate.id, bootstrap.id, expression));
      });
    });

    group('evaluateInFrame', () {
      String isolateId;
      Stream<Event> stream;
      ScriptList scripts;
      ScriptRef mainScript;

      setUpAll(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();

        isolateId = vm.isolates.first.id;
        scripts = await service.getScripts(isolateId);
        await service.streamListen('Debug');
        stream = service.onEvent('Debug');
        mainScript = scripts.scripts
            .firstWhere((script) => script.uri.contains('main.dart'));
      });

      setUp(() async {
        setCurrentLogWriter();
      });

      test('emits EVALUATE_IN_FRAME events on RPC error', () async {
        final expression = 'some-bad-expression';
        await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isFalse,
              'exception': isA<RPCError>().having((e) => e.message, 'message',
                  contains('program is not paused')),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) {}));
      });

      test('emits EVALUATE_IN_FRAME events on evaluation error', () async {
        final line = await context.findBreakpointLine(
            'callPrintCount', isolateId, mainScript);
        final bp = await service.addBreakpoint(isolateId, mainScript.id, line);
        // Wait for breakpoint to trigger.
        await stream
            .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

        // Evaluation succeeds and return ErrorRef containing compilation error,
        // so event is marked as success.
        final expression = 'some-bad-expression';
        await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isFalse,
              'error': isA<ErrorRef>(),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) {}));

        await service.removeBreakpoint(isolateId, bp.id);
        await service.resume(isolateId);
      });

      test('emits EVALUATE_IN_FRAME events on evaluation success', () async {
        final line = await context.findBreakpointLine(
            'callPrintCount', isolateId, mainScript);
        final bp = await service.addBreakpoint(isolateId, mainScript.id, line);
        // Wait for breakpoint to trigger.
        await stream
            .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

        // Evaluation succeeds and return InstanceRef,
        // so event is marked as success.
        final expression = 'true';
        await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isTrue,
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) {}));

        await service.removeBreakpoint(isolateId, bp.id);
        await service.resume(isolateId);
      });
    });

    group('getSourceReport', () {
      String isolateId;
      ScriptList scripts;
      ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();
        isolateId = vm.isolates.first.id;
        scripts = await service.getScripts(isolateId);

        mainScript = scripts.scripts
            .firstWhere((script) => script.uri.contains('main.dart'));
      });

      test('emits GET_SOURCE_REPORT events', () async {
        await expectEventDuring(
            matchesEvent(DwdsEventKind.getSourceReport, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getSourceReport(
                isolateId, [SourceReportKind.kPossibleBreakpoints],
                scriptId: mainScript.id));
      });
    });

    group('getSripts', () {
      String isolateId;

      setUp(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();
        isolateId = vm.isolates.first.id;
      });

      test('emits GET_SCRIPTS events', () async {
        await expectEventDuring(
            matchesEvent(DwdsEventKind.getScripts, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getScripts(isolateId));
      });
    });

    group('getIsolate', () {
      String isolateId;

      setUp(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();
        isolateId = vm.isolates.first.id;
      });

      test('emits GET_ISOLATE events', () async {
        await expectEventDuring(
            matchesEvent(DwdsEventKind.getIsolate, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getIsolate(isolateId));
      });
    });

    group('getVM', () {
      setUp(() async {
        setCurrentLogWriter();
      });

      test('emits GET_VM events', () async {
        await expectEventDuring(
            matchesEvent(DwdsEventKind.getVM, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getVM());
      });
    });

    group('hotRestart', () {
      setUp(() async {
        setCurrentLogWriter();
      });

      test('emits HOT_RESTART event', () async {
        final client = context.debugConnection.vmService;

        await expectEventDuring(
            matchesEvent(DwdsEventKind.hotRestart, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => client.callServiceExtension('hotRestart'));
      });
    });

    group('resume', () {
      String isolateId;
      Stream<Event> stream;
      ScriptList scripts;
      ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter();
        final vm = await service.getVM();
        isolateId = vm.isolates.first.id;
        scripts = await service.getScripts(isolateId);
        await service.streamListen('Debug');
        stream = service.onEvent('Debug');
        mainScript = scripts.scripts
            .firstWhere((script) => script.uri.contains('main.dart'));
        final line = await context.findBreakpointLine(
            'callPrintCount', isolateId, mainScript);
        final bp = await service.addBreakpoint(isolateId, mainScript.id, line);
        // Wait for breakpoint to trigger.
        await stream
            .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);
        await service.removeBreakpoint(isolateId, bp.id);
      });

      tearDown(() async {
        // Resume execution to not impact other tests.
        await service.resume(isolateId);
      });

      test('emits RESUME events', () async {
        await expectEventDuring(
            matchesEvent(DwdsEventKind.resume, {
              'step': 'Into',
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.resume(isolateId, step: 'Into'));
      });
    });

    group('fullReload', () {
      setUp(() async {
        setCurrentLogWriter();
      });

      test('emits FULL_RELOAD event', () async {
        final client = context.debugConnection.vmService;

        await expectEventDuring(
            matchesEvent(DwdsEventKind.fullReload, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => client.callServiceExtension('fullReload'));
      });
    });
  }, timeout: Timeout.factor(2));
}

/// Matches event recursively.
Matcher matchesEvent(String type, Map<String, Object> payload) {
  return isA<DwdsEvent>()
      .having((e) => e.type, 'type', type)
      .having((e) => e.payload.keys, 'payload.keys', payload.keys)
      .having((e) => e.payload.values, 'payload.values', payload.values);
}

/// Pipes the [stream] into a newly created stream.
/// Returns the new stream which is closed on [timeout].
Stream<DwdsEvent> pipe(Stream<DwdsEvent> stream, {Timeout timeout}) {
  final controller = StreamController<DwdsEvent>();
  final defaultTimeout = const Timeout(Duration(seconds: 20));
  timeout ??= defaultTimeout;
  unawaited(stream
      .forEach(controller.add)
      .timeout(defaultTimeout.merge(timeout).duration)
      .catchError((_) {})
      .then((value) => controller.close()));
  return controller.stream;
}
