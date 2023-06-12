// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  this_access() {
    if (this is D) {
      this;
    }
  }

  Object x = 'foo';

  field_by_scope() {
    if (x is String) {
      x;
    }
  }

  Object get y => 'foo';

  getter_by_scope() {
    if (y is String) {
      y;
    }
  }
}

class D extends C {}

field_by_access(C c) {
  if (c.x is String) {
    c.x;
  }
}

getter_by_access(C c) {
  if (c.y is String) {
    c.y;
  }
}

Object f() => 'foo';

top_level_function() {
  if (f is int Function()) {
    f;
  }
}

local_function() {
  Object g() => 'foo';
  if (g is int Function()) {
    g;
  }
}

Object a = 'foo';

top_level_variable() {
  if (a is String) {
    a;
  }
}

Object get b => 'foo';

top_level_getter() {
  if (b is String) {
    b;
  }
}
