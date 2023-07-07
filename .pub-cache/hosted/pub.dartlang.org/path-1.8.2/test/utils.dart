// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A matcher for a closure that throws a [p.PathException].
final throwsPathException = throwsA(const TypeMatcher<p.PathException>());

void expectEquals(p.Context context, String path1, String path2) {
  expect(context.equals(path1, path2), isTrue,
      reason: 'Expected "$path1" to equal "$path2".');
  expect(context.equals(path2, path1), isTrue,
      reason: 'Expected "$path2" to equal "$path1".');
  expect(context.hash(path1), equals(context.hash(path2)),
      reason: 'Expected "$path1" to hash the same as "$path2".');
}

void expectNotEquals(p.Context context, String path1, String path2,
    {bool allowSameHash = false}) {
  expect(context.equals(path1, path2), isFalse,
      reason: 'Expected "$path1" not to equal "$path2".');
  expect(context.equals(path2, path1), isFalse,
      reason: 'Expected "$path2" not to equal "$path1".');

  // Hash collisions are allowed, but the test author should be explicitly aware
  // when they occur.
  if (allowSameHash) return;
  expect(context.hash(path1), isNot(equals(context.hash(path2))),
      reason: 'Expected "$path1" not to hash the same as "$path2".');
}
