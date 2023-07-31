// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

import '../error_matchers.dart';
import '../interfaces.dart';
import '../type_matcher.dart';
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
@Deprecated('throwsCyclicInitializationError has been deprecated, because '
    'the type will longer exists in Dart 3.0. It will now catch any kind of '
    'error, not only CyclicInitializationError.')
const Matcher throwsCyclicInitializationError = Throws(TypeMatcher<Error>());

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
@Deprecated('throwsNullThrownError has been deprecated, because '
    'NullThrownError has been replaced with TypeError. '
    'Use `throwsA(isA<TypeError>())` instead.')
const Matcher throwsNullThrownError = Throws(TypeMatcher<TypeError>());

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
