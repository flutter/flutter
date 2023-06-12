// Copyright(c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

Int64 make64(int lo, [int? hi]) {
  hi ??= lo < 0 ? -1 : 0;
  return Int64.fromInts(hi, lo);
}

Matcher expect64(int lo, [int? hi]) {
  final expected = make64(lo, hi);
  return predicate((Int64 actual) => actual == expected);
}
