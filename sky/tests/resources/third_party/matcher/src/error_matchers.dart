// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.error_matchers;

import 'core_matchers.dart';
import 'interfaces.dart';

/// A matcher for ArgumentErrors.
const Matcher isArgumentError = const _ArgumentError();

class _ArgumentError extends TypeMatcher {
  const _ArgumentError() : super("ArgumentError");
  bool matches(item, Map matchState) => item is ArgumentError;
}

/// A matcher for ConcurrentModificationError.
const Matcher isConcurrentModificationError =
    const _ConcurrentModificationError();

class _ConcurrentModificationError extends TypeMatcher {
  const _ConcurrentModificationError() : super("ConcurrentModificationError");
  bool matches(item, Map matchState) => item is ConcurrentModificationError;
}

/// A matcher for CyclicInitializationError.
const Matcher isCyclicInitializationError = const _CyclicInitializationError();

class _CyclicInitializationError extends TypeMatcher {
  const _CyclicInitializationError() : super("CyclicInitializationError");
  bool matches(item, Map matchState) => item is CyclicInitializationError;
}

/// A matcher for Exceptions.
const Matcher isException = const _Exception();

class _Exception extends TypeMatcher {
  const _Exception() : super("Exception");
  bool matches(item, Map matchState) => item is Exception;
}

/// A matcher for FormatExceptions.
const Matcher isFormatException = const _FormatException();

class _FormatException extends TypeMatcher {
  const _FormatException() : super("FormatException");
  bool matches(item, Map matchState) => item is FormatException;
}

/// A matcher for NoSuchMethodErrors.
const Matcher isNoSuchMethodError = const _NoSuchMethodError();

class _NoSuchMethodError extends TypeMatcher {
  const _NoSuchMethodError() : super("NoSuchMethodError");
  bool matches(item, Map matchState) => item is NoSuchMethodError;
}

/// A matcher for NullThrownError.
const Matcher isNullThrownError = const _NullThrownError();

class _NullThrownError extends TypeMatcher {
  const _NullThrownError() : super("NullThrownError");
  bool matches(item, Map matchState) => item is NullThrownError;
}

/// A matcher for RangeErrors.
const Matcher isRangeError = const _RangeError();

class _RangeError extends TypeMatcher {
  const _RangeError() : super("RangeError");
  bool matches(item, Map matchState) => item is RangeError;
}

/// A matcher for StateErrors.
const Matcher isStateError = const _StateError();

class _StateError extends TypeMatcher {
  const _StateError() : super("StateError");
  bool matches(item, Map matchState) => item is StateError;
}

/// A matcher for UnimplementedErrors.
const Matcher isUnimplementedError = const _UnimplementedError();

class _UnimplementedError extends TypeMatcher {
  const _UnimplementedError() : super("UnimplementedError");
  bool matches(item, Map matchState) => item is UnimplementedError;
}

/// A matcher for UnsupportedError.
const Matcher isUnsupportedError = const _UnsupportedError();

class _UnsupportedError extends TypeMatcher {
  const _UnsupportedError() : super("UnsupportedError");
  bool matches(item, Map matchState) => item is UnsupportedError;
}
