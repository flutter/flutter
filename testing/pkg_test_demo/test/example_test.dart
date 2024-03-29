// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

void main() {
  test('String.split() splits the string on the delimiter', () {
    const String string = 'foo,bar,baz';
    expect(string.split(','), equals(<String>['foo', 'bar', 'baz']));
  });

  test('String.trim() removes surrounding whitespace', () {
    const String string = '  foo ';
    expect(string.trim(), equals('foo'));
  });
}
