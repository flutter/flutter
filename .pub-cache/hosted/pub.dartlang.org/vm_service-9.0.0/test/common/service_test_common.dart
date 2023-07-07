// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_test_common;

import 'dart:async';

import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

typedef IsolateTest = Future<void> Function(
    VmService service, IsolateRef isolate);
typedef VMTest = Future<void> Function(VmService service);

Future<void> smartNext(VmService service, IsolateRef isolateRef) async {
  print('smartNext');
  final isolate = await service.getIsolate(isolateRef.id!);
  Event event = isolate.pauseEvent!;
  if ((event.kind == EventKind.kPauseBreakpoint)) {
    // TODO(bkonyi): remove needless refetching of isolate object.
    if (event.atAsyncSuspension ?? false) {
      return asyncNext(service, isolateRef);
    } else {
      return syncNext(service, isolateRef);
    }
  } else {
    throw 'The program is already running';
  }
}

Future<void> asyncNext(VmService service, IsolateRef isolateRef) async {
  print('asyncNext');
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if ((event.kind == EventKind.kPauseBreakpoint)) {
    dynamic event = isolate.pauseEvent;
    if (!event.atAsyncSuspension) {
      throw 'No async continuation at this location';
    } else {
      await service.resume(id, step: 'OverAsyncSuspension');
    }
  } else {
    throw 'The program is already running';
  }
}

Future<void> syncNext(VmService service, IsolateRef isolateRef) async {
  print('syncNext');
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if ((event.kind == EventKind.kPauseBreakpoint)) {
    await service.resume(id, step: 'Over');
  } else {
    throw 'The program is already running';
  }
}

Future<void> hasPausedFor(
    VmService service, IsolateRef isolateRef, String kind) async {
  Completer<dynamic>? completer = Completer();
  late var subscription;
  subscription = service.onDebugEvent.listen((event) async {
    if ((isolateRef.id == event.isolate!.id) && (event.kind == kind)) {
      if (completer != null) {
        try {
          await service.streamCancel(EventStreams.kDebug);
        } catch (_) {/* swallow exception */} finally {
          subscription.cancel();
          completer?.complete();
          completer = null;
        }
      }
    }
  });

  await _subscribeDebugStream(service);

  // Pause may have happened before we subscribed.
  final id = isolateRef.id!;
  final isolate = await service.getIsolate(id);
  final event = isolate.pauseEvent!;
  if ((event.kind == kind)) {
    if (completer != null) {
      try {
        await service.streamCancel(EventStreams.kDebug);
      } catch (_) {/* swallow exception */} finally {
        subscription.cancel();
        completer?.complete();
      }
    }
  }
  return completer?.future; // Will complete when breakpoint hit.
}

Future<void> hasStoppedAtBreakpoint(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseBreakpoint);
}

Future<void> hasStoppedPostRequest(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPausePostRequest);
}

Future<void> hasStoppedWithUnhandledException(
    VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseException);
}

Future<void> hasStoppedAtExit(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseExit);
}

Future<void> hasPausedAtStart(VmService service, IsolateRef isolate) {
  return hasPausedFor(service, isolate, EventKind.kPauseStart);
}

// Currying is your friend.
IsolateTest setBreakpointAtLine(int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Setting breakpoint for line $line");
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final Library lib =
        (await service.getObject(isolateId, isolate.rootLib!.id!)) as Library;
    final script = lib.scripts!.first;

    Breakpoint bpt = await service.addBreakpoint(isolateId, script.id!, line);
    print("Breakpoint is $bpt");
  };
}

IsolateTest setBreakpointAtUriAndLine(String uri, int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Setting breakpoint for line $line in $uri");
    Breakpoint bpt =
        await service.addBreakpointWithScriptUri(isolateRef.id!, uri, line);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
  };
}

IsolateTest setBreakpointAtLineColumn(int line, int column) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Setting breakpoint for line $line column $column");
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    ScriptRef script = lib.scripts!.firstWhere((s) => s.uri == lib.uri);
    Breakpoint bpt = await service.addBreakpoint(
      isolateId,
      script.id!,
      line,
      column: column,
    );
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
  };
}

IsolateTest stoppedAtLine(int line) {
  return (VmService service, IsolateRef isolateRef) async {
    print("Checking we are at line $line");

    // Make sure that the isolate has stopped.
    final id = isolateRef.id!;
    final isolate = await service.getIsolate(id);
    final event = isolate.pauseEvent!;
    expect(event.kind != EventKind.kResume, isTrue);

    final stack = await service.getStack(id);

    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));

    final top = frames[0];
    final Script script =
        (await service.getObject(id, top.location!.script!.id!)) as Script;
    int actualLine = script.getLineNumberFromTokenPos(top.location!.tokenPos!)!;
    if (actualLine != line) {
      print("Actual: $actualLine Line: $line");
      final sb = StringBuffer();
      sb.write("Expected to be at line $line but actually at line $actualLine");
      sb.write("\nFull stack trace:\n");
      for (Frame f in frames) {
        sb.write(
            " $f [${script.getLineNumberFromTokenPos(f.location!.tokenPos!)}]\n");
      }
      throw sb.toString();
    } else {
      print('Program is stopped at line: $line');
    }
  };
}

Future<void> resumeIsolate(VmService service, IsolateRef isolate) async {
  Completer completer = Completer();
  late var subscription;
  subscription = service.onDebugEvent.listen((event) async {
    if (event.kind == EventKind.kResume) {
      try {
        await service.streamCancel(EventStreams.kDebug);
      } catch (_) {/* swallow exception */} finally {
        subscription.cancel();
        completer.complete();
      }
    }
  });
  await service.streamListen(EventStreams.kDebug);
  await service.resume(isolate.id!);
  return completer.future;
}

Future<void> _subscribeDebugStream(VmService service) async {
  try {
    await service.streamListen(EventStreams.kDebug);
  } catch (_) {
    /* swallow exception */
  }
}

Future<void> _unsubscribeDebugStream(VmService service) async {
  try {
    await service.streamCancel(EventStreams.kDebug);
  } catch (_) {
    /* swallow exception */
  }
}

Future<void> resumeAndAwaitEvent(
  VmService service,
  IsolateRef isolateRef,
  String streamId,
  Function(Event) onEvent,
) async {
  final completer = Completer<void>();
  late final StreamSubscription sub;
  sub = service.onEvent(streamId).listen((event) async {
    await onEvent(event);
    await sub.cancel();
    await service.streamCancel(streamId);
    completer.complete();
  });

  await service.streamListen(streamId);
  await service.resume(isolateRef.id!);
  return completer.future;
}

IsolateTest resumeIsolateAndAwaitEvent(
  String streamId,
  Function(Event) onEvent,
) {
  return (VmService service, IsolateRef isolate) async =>
      resumeAndAwaitEvent(service, isolate, streamId, onEvent);
}

Future<void> stepOver(VmService service, IsolateRef isolateRef) async {
  await service.streamListen(EventStreams.kDebug);
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Over');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepInto(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Into');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

Future<void> stepOut(VmService service, IsolateRef isolateRef) async {
  await _subscribeDebugStream(service);
  await service.resume(isolateRef.id!, step: 'Out');
  await hasStoppedAtBreakpoint(service, isolateRef);
  await _unsubscribeDebugStream(service);
}

IsolateTest resumeProgramRecordingStops(
    List<String> recordStops, bool includeCaller) {
  return (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        final stack = await service.getStack(isolateRef.id!);
        expect(stack.frames!.length, greaterThanOrEqualTo(2));

        String brokeAt =
            await _locationToString(service, isolateRef, stack.frames![0]);
        if (includeCaller) {
          brokeAt =
              '$brokeAt (${await _locationToString(service, isolateRef, stack.frames![1])})';
        }
        recordStops.add(brokeAt);
        await service.resume(isolateRef.id!);
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateRef.id!);
    return completer.future;
  };
}

Future<String> _locationToString(
  VmService service,
  IsolateRef isolateRef,
  Frame frame,
) async {
  final location = frame.location!;
  Script script =
      await service.getObject(isolateRef.id!, location.script!.id!) as Script;
  final scriptName = basename(script.uri!);
  final tokenPos = location.tokenPos!;
  final line = script.getLineNumberFromTokenPos(tokenPos);
  final column = script.getColumnNumberFromTokenPos(tokenPos);
  return '$scriptName:$line:$column';
}

IsolateTest runStepThroughProgramRecordingStops(List<String> recordStops) {
  return (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseBreakpoint) {
        final isolate = await service.getIsolate(isolateRef.id!);
        final frame = isolate.pauseEvent!.topFrame!;
        recordStops.add(await _locationToString(service, isolateRef, frame));
        if (event.atAsyncSuspension ?? false) {
          await service.resume(isolateRef.id!,
              step: StepOption.kOverAsyncSuspension);
        } else {
          await service.resume(isolateRef.id!, step: StepOption.kOver);
        }
      } else if (event.kind == EventKind.kPauseExit) {
        await subscription.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });

    await service.streamListen(EventStreams.kDebug);
    await service.resume(isolateRef.id!);
    return completer.future;
  };
}

IsolateTest checkRecordedStops(
    List<String> recordStops, List<String> expectedStops,
    {bool removeDuplicates = false,
    bool debugPrint = false,
    String? debugPrintFile,
    int? debugPrintLine}) {
  return (VmService service, IsolateRef isolate) async {
    if (debugPrint) {
      for (int i = 0; i < recordStops.length; i++) {
        String line = recordStops[i];
        String output = line;
        int firstColon = line.indexOf(":");
        int lastColon = line.lastIndexOf(":");
        if (debugPrintFile != null &&
            debugPrintLine != null &&
            firstColon > 0 &&
            lastColon > 0) {
          int lineNumber = int.parse(line.substring(firstColon + 1, lastColon));
          int relativeLineNumber = lineNumber - debugPrintLine;
          var columnNumber = line.substring(lastColon + 1);
          var file = line.substring(0, firstColon);
          if (file == debugPrintFile) {
            output = '\$file:\${LINE+$relativeLineNumber}:$columnNumber';
          }
        }
        String comma = i == recordStops.length - 1 ? "" : ",";
        print('"$output"$comma');
      }
    }
    if (removeDuplicates) {
      recordStops = removeAdjacentDuplicates(recordStops);
      expectedStops = removeAdjacentDuplicates(expectedStops);
    }

    // Single stepping may record extra stops.
    // Allow the extra ones as long as the expected ones are recorded.
    int i = 0;
    int j = 0;
    while (i < recordStops.length && j < expectedStops.length) {
      if (recordStops[i] != expectedStops[j]) {
        // Check if recordStops[i] is an extra stop.
        int k = i + 1;
        while (k < recordStops.length && recordStops[k] != expectedStops[j]) {
          k++;
        }
        if (k < recordStops.length) {
          // Allow and ignore extra recorded stops from i to k-1.
          i = k;
        } else {
          // This will report an error.
          expect(recordStops[i], expectedStops[j]);
        }
      }
      i++;
      j++;
    }

    expect(recordStops.length >= expectedStops.length, true,
        reason: "Expects at least ${expectedStops.length} breaks, "
            "got ${recordStops.length}.");
  };
}

List<String> removeAdjacentDuplicates(List<String> fromList) {
  List<String> result = <String>[];
  String? latestLine;
  for (String s in fromList) {
    if (s == latestLine) continue;
    latestLine = s;
    result.add(s);
  }
  return result;
}
