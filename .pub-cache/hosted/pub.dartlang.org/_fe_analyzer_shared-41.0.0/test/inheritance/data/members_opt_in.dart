// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: A1:A1,Object*/
abstract class A1 {
  /*member: A1.close:void Function()*/
  void close();
}

/*class: B1:B1,Object*/
abstract class B1 {
  /*member: B1.close:Object Function()*/
  Object close();
}

/*class: C1a:A1,B1,C1a,Object*/
abstract class C1a implements A1, B1 {
  /*member: C1a.close:Object Function()*/
  Object close();
}

/*class: C1b:A1,B1,C1b,Object*/
abstract class C1b implements B1, A1 {
  /*member: C1b.close:Object Function()*/
  Object close();
}

/*class: A2:A2<T>,Object*/
abstract class A2<T> {
  /*member: A2.close:void Function()*/
  void close();
}

/*class: B2:B2<T>,Object*/
abstract class B2<T> {
  /*member: B2.close:Object Function()*/
  Object close();
}

/*class: C2a:A2<T>,B2<T>,C2a<T>,Object*/
abstract class C2a<T> implements A2<T>, B2<T> {
  /*member: C2a.close:Object Function()*/
  Object close();
}

/*class: C2b:A2<T>,B2<T>,C2b<T>,Object*/
abstract class C2b<T> implements B2<T>, A2<T> {
  /*member: C2b.close:Object Function()*/
  Object close();
}
