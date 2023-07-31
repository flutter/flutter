// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';
import 'package:string_scanner/string_scanner.dart';

/// A regular expression that matches text until a letter or whitespace.
///
/// This is intended to scan through a number without actually encoding the full
/// Dart number grammar. It doesn't stop on "e" because that can be a component
/// of numbers.
final _untilUnit = RegExp(r'[^a-df-z\s]+', caseSensitive: false);

/// A regular expression that matches a time unit.
final _unit = RegExp(r'([um]s|[dhms])', caseSensitive: false);

/// A regular expression that matches a section of whitespace.
final _whitespace = RegExp(r'\s+');

/// A class representing a modification to the default timeout for a test.
///
/// By default, a test will time out after 30 seconds. With [Timeout], that
/// can be overridden entirely; with [Timeout.factor], it can be scaled
/// relative to the default.
@Target({TargetKind.library})
class Timeout {
  /// A constant indicating that a test should never time out.
  static const none = Timeout._none();

  /// The timeout duration.
  ///
  /// If set, this overrides the default duration entirely. It's `null` for
  /// timeouts with a non-null [scaleFactor] and for [Timeout.none].
  final Duration? duration;

  /// The timeout factor.
  ///
  /// The default timeout will be multiplied by this to get the new timeout.
  /// Thus a factor of 2 means that the test will take twice as long to time
  /// out, and a factor of 0.5 means that it will time out twice as quickly.
  ///
  /// This is `null` for timeouts with a non-null [duration] and for
  /// [Timeout.none].
  final num? scaleFactor;

  /// Declares an absolute timeout that overrides the default.
  const Timeout(this.duration) : scaleFactor = null;

  /// Declares a relative timeout that scales the default.
  const Timeout.factor(this.scaleFactor) : duration = null;

  const Timeout._none()
      : scaleFactor = null,
        duration = null;

  /// Parse the timeout from a user-provided string.
  ///
  /// This supports the following formats:
  ///
  /// * `Number "x"`, which produces a relative timeout with the given scale
  ///   factor.
  ///
  /// * `(Number ("d" | "h" | "m" | "s" | "ms" | "us") (" ")?)+`, which produces
  ///   an absolute timeout with the duration given by the sum of the given
  ///   units.
  ///
  /// * `"none"`, which produces [Timeout.none].
  ///
  /// Throws a [FormatException] if [timeout] is not in a valid format
  factory Timeout.parse(String timeout) {
    var scanner = StringScanner(timeout);

    // First check for the string "none".
    if (scanner.scan('none')) {
      scanner.expectDone();
      return Timeout.none;
    }

    // Scan a number. This will be either a time unit or a scale factor.
    scanner.expect(_untilUnit, name: 'number');
    var number = double.parse((scanner.lastMatch![0])!);

    // A number followed by "x" is a scale factor.
    if (scanner.scan('x') || scanner.scan('X')) {
      scanner.expectDone();
      return Timeout.factor(number);
    }

    // Parse time units until none are left. The condition is in the middle of
    // the loop because we've already parsed the first number.
    var microseconds = 0.0;
    while (true) {
      scanner.expect(_unit, name: 'unit');
      microseconds += _microsecondsFor(number, (scanner.lastMatch![0])!);

      scanner.scan(_whitespace);

      // Scan the next number, if it's available.
      if (!scanner.scan(_untilUnit)) break;
      number = double.parse((scanner.lastMatch![0])!);
    }

    scanner.expectDone();
    return Timeout(Duration(microseconds: microseconds.round()));
  }

  /// Returns the number of microseconds in [number] [unit]s.
  static double _microsecondsFor(double number, String unit) {
    switch (unit) {
      case 'd':
        return number * 24 * 60 * 60 * 1000000;
      case 'h':
        return number * 60 * 60 * 1000000;
      case 'm':
        return number * 60 * 1000000;
      case 's':
        return number * 1000000;
      case 'ms':
        return number * 1000;
      case 'us':
        return number;
      default:
        throw ArgumentError('Unknown unit $unit.');
    }
  }

  /// Returns a new [Timeout] that merges [this] with [other].
  ///
  /// [Timeout.none] takes precedence over everything. If timeout is
  /// [Timeout.none] and [other] declares a [duration], that takes precedence.
  /// Otherwise, this timeout's [duration] or [factor] are multiplied by
  /// [other]'s [factor].
  Timeout merge(Timeout other) {
    if (this == none || other == none) return none;
    if (other.duration != null) return Timeout(other.duration);
    if (duration != null) return Timeout(duration! * other.scaleFactor!);
    return Timeout.factor(scaleFactor! * other.scaleFactor!);
  }

  /// Returns a new [Duration] from applying [this] to [base].
  ///
  /// If this is [none], returns `null`.
  Duration? apply(Duration base) {
    if (this == none) return null;
    return duration ?? base * scaleFactor!;
  }

  @override
  int get hashCode => duration.hashCode ^ 5 * scaleFactor.hashCode;

  @override
  bool operator ==(other) =>
      other is Timeout &&
      other.duration == duration &&
      other.scaleFactor == scaleFactor;

  @override
  String toString() {
    if (duration != null) return duration.toString();
    if (scaleFactor != null) return '${scaleFactor}x';
    return 'none';
  }
}
