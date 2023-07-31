// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void if_joinThenElse_ifNull(int? a, int? b) {
  if (a == null) {
    a;
    if (b == null) return;
    /*nonNullable*/ b;
  } else {
    /*nonNullable*/ a;
    if (b == null) return;
    /*nonNullable*/ b;
  }
  a;
  /*nonNullable*/ b;
}

void if_notNull_thenExit_left(int? x) {
  if (null != x) return;
  x;
}

void if_notNull_thenExit_right(int? x) {
  if (x != null) return;
  x;
}

void if_null_thenExit_left(int? x) {
  if (null == x) return;
  /*nonNullable*/ x;
}

void if_null_thenExit_right(int? x) {
  if (x == null) return;
  /*nonNullable*/ x;
}

void if_then_else(int? x) {
  if (x == null) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void if_then_elseNullableTypeVariableWithNonNullableBound<T extends int>(T? x) {
  if (x == null) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void if_then_elseTypeVariableWithNullableBound<T extends int?>(T x) {
  if (x == null) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

class C {
  void method_if_then_else(int? x) {
    if (x == null) {
      x;
    } else {
      /*nonNullable*/ x;
    }
  }

  C.constructor_if_then_else(int? x) {
    if (x == null) {
      x;
    } else {
      /*nonNullable*/ x;
    }
  }
}
