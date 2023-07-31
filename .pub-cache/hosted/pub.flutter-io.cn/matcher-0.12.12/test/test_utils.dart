// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

void shouldFail(Object? value, Matcher matcher, Object? expected) {
  var failed = false;
  try {
    expect(value, matcher);
  } on TestFailure catch (err) {
    failed = true;

    var errorString = err.message;

    if (expected is String) {
      expect(errorString, equalsIgnoringWhitespace(expected));
    } else {
      expect(errorString?.replaceAll('\n', ''), expected);
    }
  }

  expect(failed, isTrue, reason: 'Expected to fail.');
}

void shouldPass(Object? value, Matcher matcher) {
  expect(value, matcher);
}

void doesNotThrow() {}
void doesThrow() {
  throw StateError('X');
}

class Widget {
  int? price;
}

class SimpleIterable extends Iterable<int> {
  final int count;

  SimpleIterable(this.count);

  @override
  Iterator<int> get iterator => _SimpleIterator(count);
}

class _SimpleIterator implements Iterator<int> {
  int _count;
  int _current;

  _SimpleIterator(this._count) : _current = -1;

  @override
  bool moveNext() {
    if (_count > 0) {
      _current = _count;
      _count--;
      return true;
    }
    _current = -1;
    return false;
  }

  @override
  int get current => _current;
}
