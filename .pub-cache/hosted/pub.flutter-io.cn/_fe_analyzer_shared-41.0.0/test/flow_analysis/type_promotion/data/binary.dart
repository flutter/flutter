// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void ifNull(Object x) {
  ((x is num) || (throw 1)) ?? ((/*num*/ x is int) || (throw 2));
  /*num*/ x;
}

void ifNull_rightUnPromote(Object x, Object? y, Object z) {
  if (x is int) {
    /*int*/ x;
    y ?? (x = z);
    x;
  }
}

logicalOr_throw(v) {
  v is String || (throw 42);
  /*String*/ v;
}
