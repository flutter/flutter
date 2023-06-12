// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: A:A,Object*/
class A {
  /*member: A.method:int Function(int?)*/
  int method(int? i) => i ?? 0;
}

/*class: B1:A,B1,C1,Object*/
abstract class B1 extends A implements C1 {
  /*member: B1.method:int Function(int?, {dynamic optional})*/

  /*member: B1.noSuchMethod:dynamic Function(Invocation)*/
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/*class: C1:C1,Object*/
abstract class C1 {
  /*member: C1.method:int Function(int?, {dynamic optional})*/
  int method(int? i, {optional});
}
