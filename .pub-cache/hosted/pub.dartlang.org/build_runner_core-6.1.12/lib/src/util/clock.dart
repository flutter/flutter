// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A function that returns the current [DateTime].
typedef _Clock = DateTime Function();
DateTime _defaultClock() => DateTime.now();

/// Returns the current [DateTime].
///
/// May be overridden for tests using [scopeClock].
DateTime now() => (Zone.current[_Clock] as _Clock ?? _defaultClock)();

/// Runs [f], with [clock] scoped whenever [now] is called.
T scopeClock<T>(DateTime Function() clock, T Function() f) =>
    runZoned(f, zoneValues: {_Clock: clock});
