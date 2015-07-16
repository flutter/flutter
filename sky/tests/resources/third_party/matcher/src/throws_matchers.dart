// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.throws_matchers;

import 'error_matchers.dart';
import 'interfaces.dart';
import 'throws_matcher.dart';

/// A matcher for functions that throw ArgumentError.
const Matcher throwsArgumentError = const Throws(isArgumentError);

/// A matcher for functions that throw ConcurrentModificationError.
const Matcher throwsConcurrentModificationError =
    const Throws(isConcurrentModificationError);

/// A matcher for functions that throw CyclicInitializationError.
const Matcher throwsCyclicInitializationError =
    const Throws(isCyclicInitializationError);

/// A matcher for functions that throw Exception.
const Matcher throwsException = const Throws(isException);

/// A matcher for functions that throw FormatException.
const Matcher throwsFormatException = const Throws(isFormatException);

/// A matcher for functions that throw NoSuchMethodError.
const Matcher throwsNoSuchMethodError = const Throws(isNoSuchMethodError);

/// A matcher for functions that throw NullThrownError.
const Matcher throwsNullThrownError = const Throws(isNullThrownError);

/// A matcher for functions that throw RangeError.
const Matcher throwsRangeError = const Throws(isRangeError);

/// A matcher for functions that throw StateError.
const Matcher throwsStateError = const Throws(isStateError);

/// A matcher for functions that throw Exception.
const Matcher throwsUnimplementedError = const Throws(isUnimplementedError);

/// A matcher for functions that throw UnsupportedError.
const Matcher throwsUnsupportedError = const Throws(isUnsupportedError);
