// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_matcher.dart';

/// A matcher for [ArgumentError].
const isArgumentError = TypeMatcher<ArgumentError>();

/// A matcher for [CastError].
@Deprecated('CastError has been deprecated in favor of TypeError. '
    'Use `isA<TypeError>()` or, if you need compatibility with older SDKs, '
    'use `isA<CastError>()` and ignore the deprecation.')
const isCastError = TypeMatcher<CastError>();

/// A matcher for [ConcurrentModificationError].
const isConcurrentModificationError =
    TypeMatcher<ConcurrentModificationError>();

/// A matcher for [CyclicInitializationError].
const isCyclicInitializationError = TypeMatcher<CyclicInitializationError>();

/// A matcher for [Exception].
const isException = TypeMatcher<Exception>();

/// A matcher for [FormatException].
const isFormatException = TypeMatcher<FormatException>();

/// A matcher for [NoSuchMethodError].
const isNoSuchMethodError = TypeMatcher<NoSuchMethodError>();

/// A matcher for [NullThrownError].
const isNullThrownError = TypeMatcher<NullThrownError>();

/// A matcher for [RangeError].
const isRangeError = TypeMatcher<RangeError>();

/// A matcher for [StateError].
const isStateError = TypeMatcher<StateError>();

/// A matcher for [UnimplementedError].
const isUnimplementedError = TypeMatcher<UnimplementedError>();

/// A matcher for [UnsupportedError].
const isUnsupportedError = TypeMatcher<UnsupportedError>();
