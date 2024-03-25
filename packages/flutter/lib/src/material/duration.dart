// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'time.dart'; // TODO: valid to resuse?

/// A [RestorableValue] that knows how to save and restore [Duration].
///
/// {@macro flutter.widgets.RestorableNum}.
class RestorableDuration extends RestorableValue<Duration> {
  /// Creates a [RestorableDuration].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  RestorableDuration(Duration defaultValue) : _defaultValue = defaultValue;

  final Duration _defaultValue;

  @override
  Duration createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(Duration? oldValue) {
    assert(debugIsSerializableForRestoration(value.hour));
    assert(debugIsSerializableForRestoration(value.minute));
    notifyListeners();
  }

  @override
  Duration fromPrimitives(Object? data) {
    final List<Object?> timeData = data! as List<Object?>;
    return Duration(
      minutes: timeData[0]! as int,
      hours: timeData[1]! as int,
    );
  }

  @override
  Object? toPrimitives() => <int>[value.minute, value.hour];
}

/// Extract the remainders of the duration units.
extension DurationUnitRemainder on Duration {
  int get millisecond => inMilliseconds % 1000;

  int get second => inSeconds % 60;

  int get minute => inMinutes % 60;

  int get hour => inHours % 24;

  int get day => inDays;
}

/// Determines how the time picker invoked using [showDurationPicker] formats and
/// lays out the time controls.
///
/// The time picker provides layout configurations optimized for each of the
/// enum values.
enum DurationFormat {
  /// Corresponds to the ICU 'HH:mm' pattern.
  ///
  /// This format uses 24-hour two-digit zero-padded hours. Controls are always
  /// laid out horizontally. Hours are separated from minutes by one colon
  /// character.
  HH_colon_mm,

  /// Corresponds to the ICU 'HH.mm' pattern.
  ///
  /// This format uses 24-hour two-digit zero-padded hours. Controls are always
  /// laid out horizontally. Hours are separated from minutes by one dot
  /// character.
  HH_dot_mm,

  /// Corresponds to the ICU "HH 'h' mm" pattern used in Canadian French.
  ///
  /// This format uses 24-hour two-digit zero-padded hours. Controls are always
  /// laid out horizontally. Hours are separated from minutes by letter 'h'.
  frenchCanadian,

  /// Corresponds to the ICU 'H:mm' pattern.
  ///
  /// This format uses 24-hour non-padded variable-length hours. Controls are
  /// always laid out horizontally. Hours are separated from minutes by one
  /// colon character.
  H_colon_mm,
}

/// The [HourFormat] used for the given [DurationFormat].
HourFormat hourFormat({required DurationFormat of}) {
  switch (of) {
    case DurationFormat.H_colon_mm:
      return HourFormat.H;
    case DurationFormat.HH_dot_mm:
    case DurationFormat.HH_colon_mm:
    case DurationFormat.frenchCanadian:
      return HourFormat.HH;
  }
}
