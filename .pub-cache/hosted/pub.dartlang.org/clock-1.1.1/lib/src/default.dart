// Copyright 2018 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'clock.dart';

/// The key for the [Zone] value that controls the current implementation of
/// [clock].
final _clockKey = Object();

/// The key for the [Zone] value that controls whether nested zones can override
/// [clock].
final _isFinalKey = Object();

/// The default implementation of [clock] for the current [Zone].
///
/// This defaults to the system clock. It can be set within a zone using
/// [withClock].
Clock get clock => Zone.current[_clockKey] as Clock? ?? const Clock();

/// Runs [callback] with the given value for the top-level [clock] field.
///
/// This is [Zone]-scoped, so asynchronous callbacks spawned within [callback]
/// will also use the new value for [clock].
///
// ignore: deprecated_member_use_from_same_package
/// If [isFinal] is `true`, calls to [withClock] within [callback] will throw a
/// [StateError]. However, this parameter is deprecated and should be avoided.
T withClock<T>(
  Clock clock,
  T Function() callback, {
  @Deprecated('This parameter is deprecated and should be avoided')
      bool isFinal = false,
}) {
  if ((Zone.current[_isFinalKey] ?? false) == true) {
    throw StateError(
        'Cannot call withClock() within a call to withClock(isFinal = true).');
  }

  return runZoned(callback,
      zoneValues: {_clockKey: clock, _isFinalKey: isFinal});
}
