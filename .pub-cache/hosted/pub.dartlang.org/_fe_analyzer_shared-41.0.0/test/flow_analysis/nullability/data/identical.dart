// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Null nullExpr = null;

void var_identical_null(int? x) {
  if (identical(x, null)) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void var_notIdentical_null(int? x) {
  if (!identical(x, null)) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

void null_identical_var(int? x) {
  if (identical(null, x)) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void null_notIdentical_var(int? x) {
  if (!identical(null, x)) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

void var_identical_nullExpr(int? x) {
  if (identical(x, nullExpr)) {
    x;
  } else {
    x;
  }
}

void var_notIdentical_nullExpr(int? x) {
  if (!identical(x, nullExpr)) {
    x;
  } else {
    x;
  }
}

void nullExpr_identical_var(int? x) {
  if (identical(nullExpr, x)) {
    x;
  } else {
    x;
  }
}

void nullExpr_notIdentical_var(int? x) {
  if (!identical(nullExpr, x)) {
    x;
  } else {
    x;
  }
}
