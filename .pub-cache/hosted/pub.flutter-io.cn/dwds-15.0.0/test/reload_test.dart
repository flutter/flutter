// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
@Timeout(Duration(minutes: 5))
import 'package:dwds/dwds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'fixtures/context.dart';
import 'fixtures/logging.dart';

final context = TestContext(
  path: 'append_body/index.html',
);

void main() {
  // set to true for debug logging.
  final debug = false;
  group('Injected client with live reload', () {
    group('and with debugging', () {
      setUp(() async {
        setCurrentLogWriter(debug: debug);
        await context.setUp(
          reloadConfiguration: ReloadConfiguration.liveReload,
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can live reload changes ', () async {
        await context.changeInput();

        final source = await context.webDriver.pageSource;

        // A full reload should clear the state.
        expect(source.contains('Hello World!'), isFalse);
        expect(source.contains('Gary is awesome!'), isTrue);
      });
    });

    group('and without debugging', () {
      setUp(() async {
        setCurrentLogWriter(debug: debug);
        await context.setUp(
          reloadConfiguration: ReloadConfiguration.liveReload,
          enableDebugging: false,
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can live reload changes ', () async {
        await context.changeInput();

        final source = await context.webDriver.pageSource;

        // A full reload should clear the state.
        expect(source.contains('Hello World!'), isFalse);
        expect(source.contains('Gary is awesome!'), isTrue);
      });
    });

    group('and without debugging using WebSockets', () {
      setUp(() async {
        setCurrentLogWriter(debug: debug);
        await context.setUp(
          reloadConfiguration: ReloadConfiguration.liveReload,
          enableDebugging: false,
          useSse: false,
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can live reload changes ', () async {
        await context.changeInput();

        final source = await context.webDriver.pageSource;

        // A full reload should clear the state.
        expect(source.contains('Hello World!'), isFalse);
        expect(source.contains('Gary is awesome!'), isTrue);
      });
    });
  });

  group('Injected client', () {
    setUp(() async {
      setCurrentLogWriter(debug: debug);
      await context.setUp(enableExpressionEvaluation: true);
    });

    tearDown(() async {
      await context.tearDown();
    });

    test('destroys and recreates the isolate during a hot restart', () async {
      final client = context.debugConnection.vmService;
      await client.streamListen('Isolate');
      await context.changeInput();

      final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(emitsInOrder([
            _hasKind(EventKind.kIsolateExit),
            _hasKind(EventKind.kIsolateStart),
            _hasKind(EventKind.kIsolateRunnable),
          ])));

      expect(await client.callServiceExtension('hotRestart'),
          const TypeMatcher<Success>());

      await eventsDone;
    });

    test('destroys and recreates the isolate during a page refresh', () async {
      final client = context.debugConnection.vmService;
      await client.streamListen('Isolate');
      await context.changeInput();

      final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(emitsInOrder([
            _hasKind(EventKind.kIsolateExit),
            _hasKind(EventKind.kIsolateStart),
            _hasKind(EventKind.kIsolateRunnable),
          ])));

      await context.webDriver.driver.refresh();

      await eventsDone;
    });

    test('can hot restart via the service extension', () async {
      final client = context.debugConnection.vmService;
      await client.streamListen('Isolate');
      await context.changeInput();

      final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(emitsInOrder([
            _hasKind(EventKind.kIsolateExit),
            _hasKind(EventKind.kIsolateStart),
            _hasKind(EventKind.kIsolateRunnable),
          ])));

      expect(await client.callServiceExtension('hotRestart'),
          const TypeMatcher<Success>());

      await eventsDone;

      final source = await context.webDriver.pageSource;
      // Main is re-invoked which shouldn't clear the state.
      expect(source, contains('Hello World!'));
      expect(source, contains('Gary is awesome!'));
    });

    test('can send events before and after hot restart', () async {
      final client = context.debugConnection.vmService;
      await client.streamListen('Isolate');

      // The event just before hot restart might never be received,
      // but the injected client continues to work and send events
      // after hot restart.
      final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(
            _hasKind(EventKind.kServiceExtensionAdded)
                .having((e) => e.extensionRPC, 'service', 'ext.bar'),
          ));

      var vm = await client.getVM();
      var isolateId = vm.isolates.first.id;
      var isolate = await client.getIsolate(isolateId);
      var library = isolate.rootLib.uri;

      await client.evaluate(
        isolateId,
        library,
        "registerExtension('ext.foo', (method, params) {})",
      );

      expect(await client.callServiceExtension('hotRestart'),
          const TypeMatcher<Success>());

      vm = await client.getVM();
      isolateId = vm.isolates.first.id;
      isolate = await client.getIsolate(isolateId);
      library = isolate.rootLib.uri;

      await client.evaluate(
        isolateId,
        library,
        "registerExtension('ext.bar', (method, params) {})",
      );

      await eventsDone;

      final source = await context.webDriver.pageSource;
      // Main is re-invoked which shouldn't clear the state.
      expect(source, contains('Hello World!'));
    });

    test('can refresh the page via the fullReload service extension', () async {
      final client = context.debugConnection.vmService;
      await client.streamListen('Isolate');
      await context.changeInput();

      final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(emitsInOrder([
            _hasKind(EventKind.kIsolateExit),
            _hasKind(EventKind.kIsolateStart),
            _hasKind(EventKind.kIsolateRunnable),
          ])));

      expect(await client.callServiceExtension('fullReload'), isA<Success>());

      await eventsDone;

      final source = await context.webDriver.pageSource;
      // Should see only the new text
      expect(source, isNot(contains('Hello World!')));
      expect(source, contains('Gary is awesome!'));
    });

    test('can hot restart while paused', () async {
      final client = context.debugConnection.vmService;
      var vm = await client.getVM();
      var isolateId = vm.isolates.first.id;
      await client.streamListen('Debug');
      final stream = client.onEvent('Debug');
      final scriptList = await client.getScripts(isolateId);
      final main = scriptList.scripts
          .firstWhere((script) => script.uri.contains('main.dart'));
      final bpLine =
          await context.findBreakpointLine('printCount', isolateId, main);
      await client.addBreakpoint(isolateId, main.id, bpLine);
      await stream
          .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

      await context.changeInput();
      await client.callServiceExtension('hotRestart');
      final source = await context.webDriver.pageSource;

      // Main is re-invoked which shouldn't clear the state.
      expect(source.contains('Hello World!'), isTrue);
      expect(source.contains('Gary is awesome!'), isTrue);

      vm = await client.getVM();
      isolateId = vm.isolates.first.id;
      final isolate = await client.getIsolate(isolateId);

      // Previous breakpoint should still exist.
      expect(isolate.breakpoints.isNotEmpty, isTrue);
      final bp = isolate.breakpoints.first;

      // Should pause eventually.
      await stream
          .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

      expect(await client.removeBreakpoint(isolate.id, bp.id), isA<Success>());
      expect(await client.resume(isolate.id), isA<Success>());
    });

    test('can evaluate expressions after hot restart ', () async {
      final client = context.debugConnection.vmService;
      var vm = await client.getVM();
      var isolateId = vm.isolates.first.id;
      await client.streamListen('Debug');
      final stream = client.onEvent('Debug');
      final scriptList = await client.getScripts(isolateId);
      final main = scriptList.scripts
          .firstWhere((script) => script.uri.contains('main.dart'));
      final bpLine =
          await context.findBreakpointLine('printCount', isolateId, main);
      await client.addBreakpoint(isolateId, main.id, bpLine);
      await stream
          .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

      await client.callServiceExtension('hotRestart');

      vm = await client.getVM();
      isolateId = vm.isolates.first.id;
      final isolate = await client.getIsolate(isolateId);
      final library = isolate.rootLib.uri;
      final bp = isolate.breakpoints.first;

      // Should pause eventually.
      final event = await stream
          .firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

      // Expression evaluation while paused on a breakpoint should work.
      var result = await client.evaluateInFrame(
          isolate.id, event.topFrame.index, 'count');
      expect(
          result,
          isA<InstanceRef>().having((instance) => instance.valueAsString,
              'valueAsString', greaterThanOrEqualTo('0')));

      await client.removeBreakpoint(isolateId, bp.id);
      await client.resume(isolateId);

      // Expression evaluation while running should work.
      result = await client.evaluate(isolateId, library, 'true');
      expect(
          result,
          isA<InstanceRef>().having(
              (instance) => instance.valueAsString, 'valueAsString', 'true'));
    });
  });

  group('Injected client with hot restart', () {
    group('and with debugging', () {
      setUp(() async {
        setCurrentLogWriter(debug: debug);
        await context.setUp(
          reloadConfiguration: ReloadConfiguration.hotRestart,
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can hot restart changes ', () async {
        await context.changeInput();

        final source = await context.webDriver.pageSource;

        // Main is re-invoked which shouldn't clear the state.
        expect(source.contains('Hello World!'), isTrue);
        expect(source.contains('Gary is awesome!'), isTrue);
        // The ext.flutter.disassemble callback is invoked and waited for.
        expect(source,
            contains('start disassemble end disassemble Gary is awesome'));
      });

      test('fires isolate create/destroy events during hot restart', () async {
        final client = context.debugConnection.vmService;
        await client.streamListen('Isolate');

        final eventsDone = expectLater(
            client.onIsolateEvent,
            emitsThrough(emitsInOrder([
              _hasKind(EventKind.kIsolateExit),
              _hasKind(EventKind.kIsolateStart),
              _hasKind(EventKind.kIsolateRunnable),
            ])));

        await context.changeInput();

        await eventsDone;
      });
    });

    group('and without debugging', () {
      setUp(() async {
        setCurrentLogWriter(debug: debug);
        await context.setUp(
          reloadConfiguration: ReloadConfiguration.hotRestart,
          enableDebugging: false,
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can hot restart changes ', () async {
        await context.changeInput();

        final source = await context.webDriver.pageSource;

        // Main is re-invoked which shouldn't clear the state.
        expect(source.contains('Hello World!'), isTrue);
        expect(source.contains('Gary is awesome!'), isTrue);
        // The ext.flutter.disassemble callback is invoked and waited for.
        expect(source,
            contains('start disassemble end disassemble Gary is awesome'));
      });
    });
  });
}

TypeMatcher<Event> _hasKind(String kind) =>
    isA<Event>().having((e) => e.kind, 'kind', kind);
