// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';

import 'throws_matcher.dart';

/// A matcher for functions that throw ArgumentError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsArgumentError = Throws(isArgumentError);

/// A matcher for functions that throw ConcurrentModificationError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsConcurrentModificationError =
    Throws(isConcurrentModificationError);

/// A matcher for functions that throw CyclicInitializationError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsCyclicInitializationError =
    Throws(isCyclicInitializationError);

/// A matcher for functions that throw Exception.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsException = Throws(isException);

/// A matcher for functions that throw FormatException.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsFormatException = Throws(isFormatException);

/// A matcher for functions that throw NoSuchMethodError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsNoSuchMethodError = Throws(isNoSuchMethodError);

/// A matcher for functions that throw NullThrownError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsNullThrownError = Throws(isNullThrownError);

/// A matcher for functions that throw RangeError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsRangeError = Throws(isRangeError);

/// A matcher for functions that throw StateError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsStateError = Throws(isStateError);

/// A matcher for functions that throw Exception.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsUnimplementedError = Throws(isUnimplementedError);

/// A matcher for functions that throw UnsupportedError.
///
/// See [throwsA] for objects that this can be matched against.
const Matcher throwsUnsupportedError = Throws(isUnsupportedError);
