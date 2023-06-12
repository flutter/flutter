// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test/test.dart' show test, group;

import 'test_utils.dart';

void main() {
  _test(isMap, {}, name: 'Map');
  _test(isList, [], name: 'List');
  _test(isArgumentError, ArgumentError());
  // ignore: deprecated_member_use, deprecated_member_use_from_same_package
  _test(isCastError, CastError());
  _test<Exception>(isException, const FormatException());
  _test(isFormatException, const FormatException());
  _test(isStateError, StateError('oops'));
  _test(isRangeError, RangeError('oops'));
  _test(isUnimplementedError, UnimplementedError('oops'));
  _test(isUnsupportedError, UnsupportedError('oops'));
  _test(isConcurrentModificationError, ConcurrentModificationError());
  _test(isCyclicInitializationError, CyclicInitializationError());
  _test<NoSuchMethodError?>(isNoSuchMethodError, null,
      name: 'NoSuchMethodError');
  _test(isNullThrownError, NullThrownError());

  group('custom `TypeMatcher`', () {
    // ignore: deprecated_member_use_from_same_package
    _test(const isInstanceOf<String>(), 'hello');
    _test(const _StringMatcher(), 'hello');
    _test(const TypeMatcher<String>(), 'hello');
    _test(isA<String>(), 'hello');
  });
}

void _test<T>(Matcher typeMatcher, T matchingInstance, {String? name}) {
  name ??= T.toString();
  group('for `$name`', () {
    if (matchingInstance != null) {
      test('succeeds', () {
        shouldPass(matchingInstance, typeMatcher);
      });
    }

    test('fails', () {
      shouldFail(
        const _TestType(),
        typeMatcher,
        "Expected: <Instance of '$name'> Actual: <Instance of '_TestType'>"
        " Which: is not an instance of '$name'",
      );
    });
  });
}

// Validate that existing implementations continue to work.
class _StringMatcher extends TypeMatcher {
  const _StringMatcher() : super(
            // ignore: deprecated_member_use_from_same_package
            'String');

  @override
  bool matches(dynamic item, Map matchState) => item is String;
}

class _TestType {
  const _TestType();
}
