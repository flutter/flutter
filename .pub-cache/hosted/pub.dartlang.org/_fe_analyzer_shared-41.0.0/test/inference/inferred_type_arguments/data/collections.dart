// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

num n = 0;
int i = 1;
double d = 2.5;
String s = "";

use(e) {}

listLiteral() {
  /*<dynamic>*/ [];
  /*<num>*/ [n];
  /*<num>*/ [n, i];
  /*<num>*/ [n, i, d];
  /*<String>*/ [s];
  /*<Object>*/ [n, i, d, s];
}

setLiteral() {
  use(/*<dynamic,dynamic>*/ {});
  use(/*<num>*/ {n});
  use(/*<num>*/ {n, i});
  use(/*<num>*/ {n, i, d});
  use(/*<String>*/ {s});
  use(/*<Object>*/ {n, i, d, s});
}

mapLiteral() {
  use(/*<dynamic,dynamic>*/ {});
  use(/*<num,num>*/ {n: n});
  use(/*<num,num>*/ {n: n, i: n});
  use(/*<num,int>*/ {n: i, i: i});
  use(/*<num,num>*/ {n: n, i: i, d: d});
  use(/*<String,String>*/ {s: s});
  use(/*<Object,Object>*/ {n: s, i: d, d: i, s: n});
}
