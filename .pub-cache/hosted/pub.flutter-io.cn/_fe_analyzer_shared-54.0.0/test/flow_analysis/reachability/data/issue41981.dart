// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void testNotNull(Null n) {
  0;
  if (n != null)
    /*stmt: unreachable*/ 1;
  2;
}

void testIsNullableNever(Object? n) {
  0;
  if (n is Never?) 1;
  2;
}

void testIsNever(Object? n) {
  0;
  if (n is Never)
    /*stmt: unreachable*/ 1;
  2;
}

void testIsNullableNeverTypeVariable<T extends Never?>(Object? n) {
  0;
  if (n is T) 1;
  2;
}

void testIsNeverTypeVariable<T extends Never>(Object? n) {
  0;
  if (n is T)
    /*stmt: unreachable*/ 1;
  2;
}
