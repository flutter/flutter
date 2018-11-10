// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'context.dart';

/// The current system clock instance.
SystemClock get systemClock => context[SystemClock];

/// A class for making time based operations testable.
class SystemClock {
  /// A const constructor to allow subclasses to be const.
  const SystemClock();

  /// Create a clock with a fixed current time.
  const factory SystemClock.fixed(DateTime time) = _FixedTimeClock;

  /// Retrieve the current time.
  DateTime now() => DateTime.now();

  /// Compute the time a given duration ago.
  DateTime ago(Duration duration) {
    return now().subtract(duration);
  }
}

class _FixedTimeClock extends SystemClock {
  const _FixedTimeClock(this._fixedTime);

  final DateTime _fixedTime;

  @override
  DateTime now() => _fixedTime;
}
