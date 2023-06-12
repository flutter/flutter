// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Null nullExpr = null;

void var_eq_null(int? x) {
  if (x == null) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void var_notEq_null(int? x) {
  if (x != null) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

void null_eq_var(int? x) {
  if (null == x) {
    x;
  } else {
    /*nonNullable*/ x;
  }
}

void null_notEq_var(int? x) {
  if (null != x) {
    /*nonNullable*/ x;
  } else {
    x;
  }
}

void var_eq_nullExpr(int? x) {
  if (x == nullExpr) {
    x;
  } else {
    x;
  }
}

void var_notEq_nullExpr(int? x) {
  if (x != nullExpr) {
    x;
  } else {
    x;
  }
}

void nullExpr_eq_var(int? x) {
  if (nullExpr == x) {
    x;
  } else {
    x;
  }
}

void nullExpr_notEq_var(int? x) {
  if (nullExpr != x) {
    x;
  } else {
    x;
  }
}
