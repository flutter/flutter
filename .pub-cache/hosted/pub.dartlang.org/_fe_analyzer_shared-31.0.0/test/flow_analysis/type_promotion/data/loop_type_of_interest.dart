// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a type comparison happening in the body of a loop
// causes the type to be of interest after the loop, regardless of the type of
// loop.

doLoop(Object o, bool f()) {
  do {
    if (o is int) print('');
  } while (f());
  o = 1;
  /*int*/ o;
}

forEachLoop(Object o, List values) {
  for (var _ in values) {
    if (o is int) print('');
  }
  o = 1;
  /*int*/ o;
}

forLoop(Object o, int count) {
  for (int i = 0; i < count; i++) {
    if (o is int) print('');
  }
  o = 1;
  /*int*/ o;
}

whileloop(Object o, bool f()) {
  while (f()) {
    if (o is int) print('');
  }
  o = 1;
  /*int*/ o;
}
