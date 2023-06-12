// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file verify that implicit downcasts *don't* cause
// promotions.

f(int i) {}

assignment(int i, dynamic d) {
  i = d;
  d;
}

nullAwareAssignment(int i, dynamic d) {
  i ??= d;
  d;
}

compoundAssignment(num n, dynamic d) {
  n += d;
  d;
}

initialization(dynamic d) {
  int i = d;
  d;
}

parameter(dynamic d) {
  f(d);
  d;
}

ifCondition(dynamic d) {
  if (d) {}
  d;
}

ifCondition_then(dynamic d) {
  if (d) {
    d;
  }
}

ifCondition_return(dynamic d) {
  if (d) return;
  d;
}

ifElementCondition(dynamic d) {
  [if (d) null];
  d;
}

ifElementCondition_then(dynamic d) {
  [if (d) d];
}

forCondition(dynamic d) {
  for (; d;) {}
  d;
}

forCondition_body(dynamic d) {
  for (; d;) {
    d;
  }
}

forElementCondition(dynamic d) {
  [for (; d;) null];
  d;
}

forElementCondition_body(dynamic d) {
  [for (; d;) d];
}

forEachIterable(dynamic d) {
  for (var item in d) {}
  d;
}

forEachIterable_body(dynamic d) {
  for (var item in d) {
    d;
  }
}

forEachElementIterable(dynamic d) {
  [for (var item in d) null];
  d;
}

forEachElementIterable_body(dynamic d) {
  [for (var item in d) d];
}

whileCondition(dynamic d) {
  while (d) {}
  d;
}

whileCondition_body(dynamic d) {
  while (d) {
    d;
  }
}

doCondition(dynamic d) {
  do {} while (d);
  d;
}

conditionalCondition(dynamic d) {
  d ? null : null;
  d;
}

conditionalCondition_thenElse(dynamic d) {
  d ? d : d;
}

andLhs(dynamic d, bool b) {
  d && b;
  d;
}

andRhs(dynamic d, bool b) {
  b && d;
  d;
}

andBoth(dynamic d, bool b) {
  d && d;
}

orLhs(dynamic d, bool b) {
  d || b;
  d;
}

orRhs(dynamic d, bool b) {
  b || d;
  d;
}

orBotn(dynamic d, bool b) {
  d || d;
}

logicalNot(dynamic d, bool b) {
  !d;
  d;
}

await_(dynamic d) async {
  await d;
  d;
}
