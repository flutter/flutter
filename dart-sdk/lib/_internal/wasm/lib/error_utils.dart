// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';
import 'dart:_internal';

/// Optimized methods for index checks.
///
/// They are designed such that
///   * actual index checks will be inlined
///   * the slow path (which throws) is outlined
///   * in --minify mode the slow paths do not use the passed arguments
///     => together with signature shaking the parameters will all be removed
///   * BCE methods: eliminate bounds checks iff `--omit-bounds-checks` is on
///
/// All methods assume `length` is non-negative.
class IndexErrorUtils {
  /// Index check that can be disabled with `--omit-bounds-checks`.
  @pragma("wasm:prefer-inline")
  static void checkIndexBCE(int index, int length, [String? name]) {
    assert(length >= 0);
    if (checkBounds && length.leU(index)) {
      _throwIndexError(index, length, name);
    }
  }

  @pragma("wasm:prefer-inline")
  static void checkIndex(int index, int length, [String? name]) {
    assert(length >= 0);
    if (length.leU(index)) {
      _throwIndexError(index, length, name);
    }
  }
}

/// Optimized methods for range checks.
///
/// They are designed such that
///   * actual index/range checks will be inlined
///   * the slow path (which throws) is outlined
///   * in --minify mode the slow paths do not use the passed arguments
///     => together with signature shaking the parameters will all be removed
///
/// Most methods assume `length` or `max` values are non-negative.
class RangeErrorUtils {
  /// Checks `0 <= value <= maxValue`.
  ///
  /// Assumes [maxValue] is non-negative.
  @pragma("wasm:prefer-inline")
  static void checkValueBetweenZeroAndPositiveMax(
    int value,
    int maxValue, [
    String? name,
    String? message,
  ]) {
    assert(maxValue >= 0);
    if (maxValue.ltU(value)) {
      _throwRangeError(value, 0, maxValue, name, message);
    }
  }

  /// Checks `minValue <= value <= maxValue`.
  @pragma("wasm:prefer-inline")
  static int checkValueInInterval(
    int value,
    int minValue,
    int maxValue, [
    String? name,
    String? message,
  ]) {
    if (value < minValue || value > maxValue) {
      _throwRangeError(value, minValue, maxValue, name, message);
    }
    return value;
  }

  /// Checks `0 <= start <= end <= length`.
  ///
  /// If [end] is omitted it defaults to [length].
  /// Returns [end] if provided otherwise [length].
  ///
  /// Assumes [length] is non-negative.
  @pragma("wasm:prefer-inline")
  static int checkValidRange(
    int start,
    int? end,
    int length, [
    String? name,
    String? endName,
  ]) {
    assert(length >= 0);
    end ??= length;
    if (end.ltU(start)) {
      _throwRangeError(start, 0, length, name);
    }
    if (length.ltU(end)) {
      _throwRangeError(end, start, length, endName ?? name);
    }
    return end;
  }

  /// Checks `offset % alignment == 0`.
  @pragma("wasm:prefer-inline")
  static void checkAlignment(int offset, int alignment) {
    if ((offset % alignment) != 0) {
      _throwRangeAlignmentError(offset, alignment);
    }
  }

  /// Checks `0 < value`.
  @pragma("wasm:prefer-inline")
  static void checkNotNegative(int value, [String? name]) {
    if (value < 0) {
      _throwNegativeError(value, name);
    }
  }

  /// Checks `0 < value`.
  @pragma("wasm:prefer-inline")
  static void checkPositive(int value, [String? name]) {
    if (value <= 0) {
      _throwNegativeOrZeroError(value, name);
    }
  }
}

@pragma("wasm:never-inline")
Never _throwIndexError(int invalidValue, int length, String? name) {
  if (minify) throw _indexErrorWithoutDetails;
  throw IndexError.withLength(invalidValue, length, name: name);
}

@pragma("wasm:never-inline")
Never _throwRangeError(
  int invalidValue,
  int min,
  int max, [
  String? name,
  String? message,
]) {
  if (minify) throw _rangeErrorWithoutDetails;
  throw RangeError.range(invalidValue, min, max, name, message);
}

@pragma("wasm:never-inline")
Never _throwRangeAlignmentError(int offset, int alignment) {
  if (minify) throw _alignmentErrorWithoutDetails;
  throw RangeError('Offset ($offset) must be a multiple of $alignment');
}

@pragma("wasm:never-inline")
Never _throwNegativeError(int value, [String? name]) {
  if (minify) throw _negativeValueErrorWithoutDetails;
  throw RangeError.range(value, 0, null, name);
}

@pragma("wasm:never-inline")
Never _throwNegativeOrZeroError(int value, [String? name]) {
  if (minify) throw _negativeOrZeroValueErrorWithoutDetails;
  throw RangeError.range(value, 1, null, name);
}

const _indexErrorWithoutDetails = _ErrorWithoutDetails(
  'IndexError (details omitted due to --minify)',
);
const _rangeErrorWithoutDetails = _ErrorWithoutDetails(
  'RangeError (details omitted due to --minify)',
);
const _alignmentErrorWithoutDetails = _ErrorWithoutDetails(
  'Offset had incorrect alignment (details omitted due to --minify)',
);
const _negativeValueErrorWithoutDetails = _ErrorWithoutDetails(
  'Value was negative (details omitted due to --minify)',
);
const _negativeOrZeroValueErrorWithoutDetails = _ErrorWithoutDetails(
  'Value was negative or zero (details omitted due to --minify)',
);

class _ErrorWithoutDetails implements Error {
  final String _message;
  const _ErrorWithoutDetails(this._message);

  StackTrace? get stackTrace => null;

  String toString() => _message;
}

const _TypeErrorWithoutDetails typeErrorWithoutDetails =
    _TypeErrorWithoutDetails();

class _TypeErrorWithoutDetails implements TypeError {
  const _TypeErrorWithoutDetails();

  StackTrace? get stackTrace => null;

  String toString() =>
      'Runtime type check failed (details omitted due to --minify)';
}
