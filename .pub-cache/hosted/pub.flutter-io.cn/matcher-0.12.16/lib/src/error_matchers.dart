// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_matcher.dart';

/// A matcher for [ArgumentError].
const isArgumentError = TypeMatcher<ArgumentError>();

/// A matcher for [TypeError].
@Deprecated('CastError has been deprecated in favor of TypeError. ')
const isCastError = TypeMatcher<TypeError>();

/// A matcher for [ConcurrentModificationError].
const isConcurrentModificationError =
    TypeMatcher<ConcurrentModificationError>();

/// A matcher for [Error].
@Deprecated(
    'CyclicInitializationError is deprecated and will be removed in Dart 3. '
    'Use `isA<Error>()` instead.')
const isCyclicInitializationError = TypeMatcher<Error>();

/// A matcher for [Exception].
const isException = TypeMatcher<Exception>();

/// A matcher for [FormatException].
const isFormatException = TypeMatcher<FormatException>();

/// A matcher for [NoSuchMethodError].
const isNoSuchMethodError = TypeMatcher<NoSuchMethodError>();

/// A matcher for [TypeError].
@Deprecated('NullThrownError is deprecated and will be removed in Dart 3. '
    'Use `isA<TypeError>()` instead.')
const isNullThrownError = TypeMatcher<TypeError>();

/// A matcher for [RangeError].
const isRangeError = TypeMatcher<RangeError>();

/// A matcher for [StateError].
const isStateError = TypeMatcher<StateError>();

/// A matcher for [UnimplementedError].
const isUnimplementedError = TypeMatcher<UnimplementedError>();

/// A matcher for [UnsupportedError].
const isUnsupportedError = TypeMatcher<UnsupportedError>();
