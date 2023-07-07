// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void outerIsType_assignedInCase(int e, Object x) {
  if (x is String) {
    switch (e) {
      L:
      case 1:
        x;
        break;
      case 2: // no label
        /*String*/ x;
        break;
      case 3:
        x = 42;
        continue L;
    }
    x;
  }
}

void case_falls_through_end(int i, Object o) {
  switch (i) {
    case 1:
      if (o is! int) return;
      /*int*/ o;
      break;
    case 2:
      o;
  }
  o;
}
