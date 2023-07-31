// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void forEachStatement(Object x) {
  if (x is int) {
    /*int*/ x;
    for (x in [0]) {
      /*int*/ x;
    }
  }
}

forEachElementInListLiteral(Object x) {
  if (x is int) {
    /*int*/ x;
    return [
      for (x in [0]) /*int*/ x
    ];
  }
}

forEachElementInMapLiteral(Object x) {
  if (x is int) {
    /*int*/ x;
    return {
      for (x in [0]) /*int*/ x: /*int*/ x
    };
  }
}

forEachElementInSetLiteral(Object x) {
  if (x is int) {
    /*int*/ x;
    return {
      for (x in [0]) /*int*/ x
    };
  }
}
