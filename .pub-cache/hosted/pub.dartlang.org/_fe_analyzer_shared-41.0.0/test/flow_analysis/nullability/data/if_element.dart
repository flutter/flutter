// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void list_if_notNull_then_else_left(int? x) {
  [if (null != x) /*nonNullable*/ x else x];
}

void list_if_notNull_then_else_right(int? x) {
  [if (x != null) /*nonNullable*/ x else x];
}

void list_if_notNull_thenExit_left(int? x) {
  [if (null != x) throw 42, x];
}

void list_if_notNull_thenExit_right(int? x) {
  [if (x != null) throw 42, x];
}

void list_if_null_then_else_left(int? x) {
  [if (null == x) x else /*nonNullable*/ x ];
}

void list_if_null_then_else_right(int? x) {
  [if (x == null) x else /*nonNullable*/ x ];
}

void list_if_null_thenExit_left(int? x) {
  [if (null == x) throw 42, /*nonNullable*/ x];
}

void list_if_null_thenExit_right(int? x) {
  [if (x == null) throw 42, /*nonNullable*/ x];
}

map_if_notNull_then_else_left(int? x) {
  return {if (null != x) /*nonNullable*/ x: /*nonNullable*/ x else x: x};
}

map_if_notNull_then_else_right(int? x) {
  return {if (x != null) /*nonNullable*/ x: /*nonNullable*/ x else x: x};
}

map_if_notNull_thenExit_left(int? x) {
  return {if (null != x) throw 42: 0, x: x};
}

map_if_notNull_thenExit_right(int? x) {
  return {if (x != null) throw 42: 0, x: x};
}

map_if_null_then_else_left(int? x) {
  return {if (null == x) x: x else /*nonNullable*/ x: /*nonNullable*/ x };
}

map_if_null_then_else_right(int? x) {
  return {if (x == null) x: x else /*nonNullable*/ x: /*nonNullable*/ x };
}

map_if_null_thenExit_left(int? x) {
  return {if (null == x) throw 42: 0, /*nonNullable*/ x: /*nonNullable*/ x };
}

map_if_null_thenExit_right(int? x) {
  return {if (x == null) throw 42: 0, /*nonNullable*/ x: /*nonNullable*/ x };
}

set_if_notNull_then_else_left(int? x) {
  return {if (null != x) /*nonNullable*/ x else x};
}

set_if_notNull_then_else_right(int? x) {
  return {if (x != null) /*nonNullable*/ x else x};
}

set_if_notNull_thenExit_left(int? x) {
  return {if (null != x) throw 42, x};
}

set_if_notNull_thenExit_right(int? x) {
  return {if (x != null) throw 42, x};
}

set_if_null_then_else_left(int? x) {
  return {if (null == x) x else /*nonNullable*/ x };
}

set_if_null_then_else_right(int? x) {
  return {if (x == null) x else /*nonNullable*/ x };
}

set_if_null_thenExit_left(int? x) {
  return {if (null == x) throw 42, /*nonNullable*/ x};
}

set_if_null_thenExit_right(int? x) {
  return {if (x == null) throw 42, /*nonNullable*/ x};
}

class C {
  C.constructor_if_then_else(int? x) {
    [if (x == null) x else /*nonNullable*/ x ];
  }

  void method_if_then_else(int? x) {
    [if (x == null) x else /*nonNullable*/ x ];
  }
}
