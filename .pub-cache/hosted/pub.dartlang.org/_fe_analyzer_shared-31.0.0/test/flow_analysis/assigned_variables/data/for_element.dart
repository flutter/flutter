// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: cStyle:declared={a, b, c, d}, assigned={a, b, c, d}*/
cStyle(int a, int b, int c, int d) {
  [/*assigned={b, c, d}*/ for (a = 0; (b = 0) != 0; c = 0) (d = 0)];
}

/*member: cStyle_unparenthesized:declared={a, b, c, d, e}, read={c}, assigned={a, b, d, e}*/
cStyle_unparenthesized(int a, bool b, bool c, int d, int e) {
  [/*read={c}, assigned={b, d, e}*/ for (a = 0; b = c; d = 0) e = 0];
}

/*member: cStyleWithDeclaration:declared={a, b, c, d, e}, assigned={a, b, c, d}*/
cStyleWithDeclaration(int a, int b, int c, int d) {
  [/*assigned={b, c, d}*/ for (int e = (a = 0); (b = 0) != 0; c = 0) (d = 0)];
}

/*member: cStyleWithDeclaration_unparenthesized:declared={a, b, c, d, e, f}, read={c}, assigned={a, b, d, e}*/
cStyleWithDeclaration_unparenthesized(int a, bool b, bool c, int d, int e) {
  [/*read={c}, assigned={b, d, e}*/ for (int f = a = 0; b = c; d = 0) e = 0];
}

/*member: forEach:declared={a, b, c}, assigned={a, b, c}*/
forEach(int a, int b, int c) {
  [
    /*assigned={c}*/ for (a in [b = 0]) (c = 0)
  ];
}

/*member: forEach_unparenthesized:declared={a, b, c}, assigned={a, b, c}*/
forEach_unparenthesized(int a, int b, int c) {
  [
    /*assigned={c}*/ for (a in [b = 0]) c = 0
  ];
}

/*member: forEachWithDeclaration:declared={a, b, c}, assigned={a, b}*/
forEachWithDeclaration(int a, int b) {
  [
    /*assigned={b}*/ for (var c in [a = 0]) (b = 0)
  ];
}

/*member: forEachWithDeclaration_unparenthesized:declared={a, b, c}, assigned={a, b}*/
forEachWithDeclaration_unparenthesized(int a, int b) {
  [
    /*assigned={b}*/ for (var c in [a = 0]) b = 0
  ];
}
