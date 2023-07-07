// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: A:A<T>,Object*/
class A<T> {
  /*member: A.member:T Function()*/
  T member() => throw "Unreachable";
}

/*class: B:A<T>,B<T>,Object*/
/*member: B.member:T Function()*/
class B<T> extends A<T> {}

/*class: D0:A<Object?>,B<Object?>,D0,Object*/
/*member: D0.member:Object? Function()*/
class D0 extends A<dynamic> implements B<Object?> {}

/*class: D1:A<Object?>,B<dynamic>,D1,Object*/
/*member: D1.member:Object? Function()*/
class D1 extends A<Object?> implements B<dynamic> {}

/*class: D2:A<Object?>,B<Object?>,D2,Object*/
/*member: D2.member:Object? Function()*/
class D2 extends A<void> implements B<Object?> {}

/*class: D3:A<Object?>,B<void>,D3,Object*/
/*member: D3.member:Object? Function()*/
class D3 extends A<Object?> implements B<void> {}

/*class: D4:A<Object?>,B<dynamic>,D4,Object*/
/*member: D4.member:Object? Function()*/
class D4 extends A<void> implements B<dynamic> {}

/*class: D5:A<Object?>,B<void>,D5,Object*/
/*member: D5.member:Object? Function()*/
class D5 extends A<dynamic> implements B<void> {}

/*class: D6:A<void>,B<void>,D6,Object*/
/*member: D6.member:void Function()*/
class D6 extends A<void> implements B<void> {}

/*class: D7:A<dynamic>,B<dynamic>,D7,Object*/
/*member: D7.member:dynamic Function()*/
class D7 extends A<dynamic> implements B<dynamic> {}
