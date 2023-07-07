// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates how isolates can get enabled for COM threading, even if the
// isolate is part of a thread which wasn't originally initialized for COM.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

enum ApartmentType {
  current(-1),
  singleThreaded(0),
  multiThreaded(1),
  neutral(2),
  mainSingleThreaded(3);

  final int value;
  const ApartmentType(this.value);

  factory ApartmentType.fromValue(int value) =>
      ApartmentType.values.firstWhere((elem) => elem.value == value);
}

enum ApartmentTypeQualifier {
  none(0),
  implicitMTA(1),
  neutralOnMTA(2),
  neutralOnSTA(3),
  neutralOnImplicitMTA(4),
  neutralOnMainSTA(5),
  applicationSTA(6);

  final int value;
  const ApartmentTypeQualifier(this.value);

  factory ApartmentTypeQualifier.fromValue(int value) =>
      ApartmentTypeQualifier.values.firstWhere((elem) => elem.value == value);
}

class ThreadContext {
  final int id;
  final ApartmentType type;
  final ApartmentTypeQualifier qualifier;

  const ThreadContext(this.id, this.type, this.qualifier);

  @override
  String toString() => '#$id: [${type.name}, ${qualifier.name}]';
}

void initializeMTA() {
  final pCookie = calloc<IntPtr>();
  try {
    // Ensure an multi-threaded apartment is created
    final res = CoIncrementMTAUsage(pCookie);
    if (FAILED(res)) throw WindowsException(res);
  } finally {
    free(pCookie);
  }
}

ThreadContext getThreadContext() {
  final pAptType = calloc<Int32>();
  final pAptQualifier = calloc<Int32>();

  try {
    final threadID = GetCurrentThreadId();

    // Get the current thread's COM model
    var hr = CoGetApartmentType(pAptType, pAptQualifier);

    if (hr == CO_E_NOTINITIALIZED) {
      // This thread hasn't been initialized for COM. Initialize and try again.
      initializeMTA();
      hr = CoGetApartmentType(pAptType, pAptQualifier);
    }
    // Some other error occurred
    if (hr != S_OK) throw WindowsException(hr);

    return ThreadContext(threadID, ApartmentType.fromValue(pAptType.value),
        ApartmentTypeQualifier.fromValue(pAptQualifier.value));
  } finally {
    free(pAptType);
    free(pAptQualifier);
  }
}

Future<void> doSomething(SendPort port) {
  // We are now in a spawned isolate. Get some information about the COM context
  // that the current _thread_ has (which may or may not be the original thread
  // where we ran CoInitialize(), depending on whether Dart is reusing the same
  // thread or not).
  final context = getThreadContext();

  // Sleep for a period of time to increase the chances that Dart creates
  // another thread.
  sleep(Duration(milliseconds: Random().nextInt(10)));

  // Pass the context information back to the spawning isolate.
  Isolate.exit(port, context);
}

Future<void> createIsolates() async {
  // Spawn 100 isolates. Isolates are an abstraction over threads. Some isolates
  // may share a thread, but Dart may spin up additional threads. This is an
  // implementation detail, but it matters for the purposes of this example
  // because only the initial thread has been initialized for COM.
  for (var i = 0; i < 100; i++) {
    final p = ReceivePort();

    await Isolate.spawn(doSomething, p.sendPort);
    final context = await p.first as ThreadContext;

    print(context.toString());
  }
}

/// Spins up a 100 isolates and interrogates them to find out their context.
///
/// Example output, showing multiple isolates executing on three separate
/// Windows threads:
/// ```
/// #1100: [mainSingleThreaded, none]
/// #4988: [multiThreaded, implicitMTA]
/// #4988: [multiThreaded, implicitMTA]
/// #4988: [multiThreaded, implicitMTA]
/// #15296: [multiThreaded, implicitMTA]
/// #15296: [multiThreaded, implicitMTA]
/// #4988: [multiThreaded, implicitMTA]
/// #1100: [mainSingleThreaded, none]
/// #4988: [multiThreaded, implicitMTA]
/// #4988: [multiThreaded, implicitMTA]
/// #1100: [mainSingleThreaded, none]
/// ...
/// ```
void main() async {
  // The main thread is initialized for the COM apartment threading model.
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

  // Should be mainSingleThreaded
  print(getThreadContext().toString());

  // Now spin up a number of threads
  await createIsolates();

  // COM will automatically get torn down when the process ends.
}
