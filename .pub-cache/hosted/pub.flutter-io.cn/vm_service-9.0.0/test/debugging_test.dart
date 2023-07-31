// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

int counter = 0;

void periodicTask(_) {
  counter++;
  counter++; // Line 16.  We set our breakpoint here.
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

int getLineNumberFromTokenPos(Script s, int token) =>
    s.tokenPosTable![token].first;

var tests = <IsolateTest>[
// Pause
  (VmService? service, IsolateRef? isolateRef) async {
    final isolateId = isolateRef!.id!;
    Completer completer = Completer();
    var stream = service!.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kPauseInterrupted) {
        subscription.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);
    await service.pause(isolateId);
    await completer.future;
    await service.streamCancel(EventStreams.kDebug);
  },

// Resume
  (VmService service, IsolateRef isolate) async {
    final isolateId = isolate.id!;
    Completer completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateId);
    await completer.future;
    await service.streamCancel(EventStreams.kDebug);
  },

// Add breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    Isolate isolate = await service.getIsolate(isolateId);
    final Library rootLib =
        (await service.getObject(isolateId, isolate.rootLib!.id!)) as Library;

    // Set up a listener to wait for breakpoint events.
    Completer completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);
    final Script script = (await service.getObject(
        isolateId, rootLib.scripts!.first.id!)) as Script;
    // Add the breakpoint.
    final Breakpoint bpt =
        await service.addBreakpoint(isolateId, script.id!, 16);
    final SourceLocation location = bpt.location;
    expect(location.script!.id, script.id);
    expect(script.getLineNumberFromTokenPos(location.tokenPos!), 16);
    expect(location.line, 16);

    isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 1);

    await completer.future; // Wait for breakpoint events.
    await service.streamCancel(EventStreams.kDebug);
  },
// We are at the breakpoint on line 16.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    final location = stack.frames![0].location!;
    Script script =
        (await service.getObject(isolateId, location.script!.id!)) as Script;
    expect(script.uri, endsWith('debugging_test.dart'));
    expect(script.getLineNumberFromTokenPos(location.tokenPos!), 16);
    expect(location.line, 16);
  },

// Stepping
  (VmService service, IsolateRef isolate) async {
    // Set up a listener to wait for breakpoint events.
    final completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });
    print('performing step over');
    await stepOver(service, isolate);
    print('step over done');
    await completer.future; // Wait for breakpoint events.
    print('breakpoint completed');
  },
// We are now at line 17.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    final location = stack.frames![0].location!;
    final Script script =
        (await service.getObject(isolateId, location.script!.id!)) as Script;
    expect(script.uri, endsWith('debugging_test.dart'));
    expect(script.getLineNumberFromTokenPos(location.tokenPos!), 17);
    expect(location.line, 17);
  },
// Remove breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    // Set up a listener to wait for breakpoint events.
    final completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) async {
      if (event.kind == EventKind.kBreakpointRemoved) {
        print('Breakpoint removed');
        final isolate = await service.getIsolate(isolateId);
        expect(isolate.breakpoints!.length, 0);
        subscription.cancel();
        completer.complete();
      }
    });

    final Isolate isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 1);
    final bpt = isolate.breakpoints!.first;
    await service.streamListen(EventStreams.kDebug);
    await service.removeBreakpoint(isolateId, bpt.id!);
    await completer.future;
    await service.streamCancel(EventStreams.kDebug);
  },
// Resume
  (VmService service, IsolateRef isolate) async {
    final completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
    await resumeIsolate(service, isolate);
    await completer.future;
  },
// Add breakpoint at function entry
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    Isolate isolate = await service.getIsolate(isolateId);
    // Set up a listener to wait for breakpoint events.
    final completer = Completer();
    var stream = service.onDebugEvent;
    late var subscription;
    subscription = stream.listen((Event event) {
      if (event.kind == EventKind.kPauseBreakpoint) {
        print('Breakpoint reached');
        subscription.cancel();
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);
    final Library rootLib =
        (await service.getObject(isolateId, isolate.rootLib!.id!)) as Library;

    // Find a specific function.
    final FuncRef function =
        rootLib.functions!.firstWhere((f) => f.name == 'periodicTask');
    expect(function, isNotNull);

    // Add the breakpoint at function entry
    final bpt = await service.addBreakpointAtEntry(isolateId, function.id!);
    final Script script =
        (await service.getObject(isolateId, bpt.location.script.id)) as Script;
    expect(script.uri, endsWith('debugging_test.dart'));
    expect(script.getLineNumberFromTokenPos(bpt.location.tokenPos), 14);
    expect(bpt.location.line, 14);

    // Refresh isolate state.
    isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 1);

    await completer.future; // Wait for breakpoint events.
  },
// We are now at line 14.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    final location = stack.frames![0].location!;
    final Script script =
        (await service.getObject(isolateId, location.script!.id!)) as Script;
    expect(script.uri, endsWith('debugging_test.dart'));
    expect(script.getLineNumberFromTokenPos(location.tokenPos!), 14);
    expect(location.line, 14);
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'debugging_test.dart',
      testeeBefore: startTimer,
    );
