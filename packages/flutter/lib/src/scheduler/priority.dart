// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'binding.dart';
library;

import 'package:flutter/foundation.dart';

/// A task priority, as passed to [SchedulerBinding.scheduleTask].
@immutable
class Priority {
  const Priority._(this._value);

  /// Integer that describes this Priority value.
  int get value => _value;
  final int _value;

  /// A task to run after all other tasks, when no animations are running.
  static const Priority idle = Priority._(0);

  /// A task to run even when animations are running.
  static const Priority animation = Priority._(100000);

  /// A task to run even when the user is interacting with the device.
  static const Priority touch = Priority._(200000);

  /// Maximum offset by which to clamp relative priorities.
  ///
  /// It is still possible to have priorities that are offset by more
  /// than this amount by repeatedly taking relative offsets, but that
  /// is generally discouraged.
  static const int kMaxOffset = 10000;

  /// Returns a priority relative to this priority.
  ///
  /// A positive [offset] indicates a higher priority.
  ///
  /// The parameter [offset] is clamped to ±[kMaxOffset].
  Priority operator +(int offset) {
    if (offset.abs() > kMaxOffset) {
      // Clamp the input offset.
      offset = kMaxOffset * offset.sign;
    }
    return Priority._(_value + offset);
  }

  /// Returns a priority relative to this priority.
  ///
  /// A positive offset indicates a lower priority.
  ///
  /// The parameter [offset] is clamped to ±[kMaxOffset].
  Priority operator -(int offset) => this + (-offset);
}
