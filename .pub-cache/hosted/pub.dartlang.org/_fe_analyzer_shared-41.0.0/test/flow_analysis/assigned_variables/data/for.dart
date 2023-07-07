// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: cStyle:declared={a, b, c, d}, assigned={a, b, c, d}*/
cStyle(int a, int b, int c, int d) {
  /*assigned={b, c, d}*/ for (a = 0; (b = 0) != 0; c = 0) {
    d = 0;
  }
}

/*member: cStyleWithDeclaration:declared={a, b, c, d, e}, assigned={a, b, c, d}*/
cStyleWithDeclaration(int a, int b, int c, int d) {
  /*assigned={b, c, d}*/ for (int e = (a = 0); (b = 0) != 0; c = 0) {
    d = 0;
  }
}

/*member: forEach:declared={a, b, c}, assigned={a, b, c}*/
forEach(int a, int b, int c) {
  /*assigned={c}*/ for (a in [b = 0]) {
    c = 0;
  }
}

/*member: forEachWithDeclaration:declared={a, b, c}, assigned={a, b}*/
forEachWithDeclaration(int a, int b) {
  /*assigned={b}*/ for (var c in [a = 0]) {
    b = 0;
  }
}
