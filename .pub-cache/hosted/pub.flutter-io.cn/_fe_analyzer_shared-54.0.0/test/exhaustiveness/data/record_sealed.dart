// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}
class B extends A {}
class C extends A {}

class Class {
  (A, A) field;
  Class(this.field);
}

method(Class c) {
  /*analyzer.
   error=non-exhaustive:Class(field: (A, A)($1: C, $2: C)),
   fields={field:(A, A),hashCode:int,runtimeType:Type},
   type=Class
  */switch (c) {
    /*analyzer.space=Class(field: ($1: A, $2: B))*/
    case Class(field: (A a, B b)):
      print('1');
    /*analyzer.space=Class(field: ($1: B, $2: A))*/
    case Class(field: (B b, A a)):
      print('2');
    default:
  }
}