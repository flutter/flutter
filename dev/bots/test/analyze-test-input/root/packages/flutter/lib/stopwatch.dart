// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../foo/stopwatch_external_lib.dart' as externallib;

typedef ExternalStopwatchConstructor = externallib.MyStopwatch Function();

class StopwatchAtHome extends Stopwatch {
  StopwatchAtHome();
  StopwatchAtHome.create(): this();

  Stopwatch get stopwatch => this;
}

void testNoStopwatches(Stopwatch stopwatch) {
  stopwatch.runtimeType;                       // OK for now, but we probably want to catch public APIs that take a Stopwatch?
  final Stopwatch localVariable = Stopwatch(); // Bad: introducing Stopwatch from dart:core.
  Stopwatch().runtimeType;                     // Bad: introducing Stopwatch from dart:core.

  (localVariable..runtimeType)                 // OK: not directly introducing Stopwatch.
   .runtimeType;

  StopwatchAtHome().runtimeType;               // Bad: introducing a Stopwatch subclass.

  Stopwatch anotherStopwatch = stopwatch;      // OK: not directly introducing Stopwatch.
  StopwatchAtHome Function() constructor = StopwatchAtHome.new; // Bad: introducing a Stopwatch constructor.
  assert(() {
    anotherStopwatch = constructor()..runtimeType;
    constructor = StopwatchAtHome.create;               // Bad: introducing a Stopwatch constructor.
    anotherStopwatch = constructor()..runtimeType;
    return true;
  }());
  anotherStopwatch.runtimeType;

  externallib.MyStopwatch.create();                     // Bad: introducing an external Stopwatch constructor.
  ExternalStopwatchConstructor? externalConstructor;

  assert(() {
    externalConstructor = externallib.MyStopwatch.new;  // Bad: introducing an external Stopwatch constructor.
    return true;
  }());
  externalConstructor?.call();

  externallib.stopwatch.runtimeType;                    // Bad: introducing an external Stopwatch.
  externallib.createMyStopwatch().runtimeType;          // Bad: calling an external function that returns a Stopwatch.
  externallib.createStopwatch().runtimeType;            // Bad: calling an external function that returns a Stopwatch.
  externalConstructor = externallib.createMyStopwatch;  // Bad: introducing the tear-off form of an external function that returns a Stopwatch.

  constructor.call().stopwatch;                         // OK: existing instance.
}

void testStopwatchIgnore(Stopwatch stopwatch) {
  Stopwatch().runtimeType;  // flutter_ignore: stopwatch (see analyze.dart)
  Stopwatch().runtimeType;  // flutter_ignore: some_other_ignores, stopwatch (see analyze.dart)
}
