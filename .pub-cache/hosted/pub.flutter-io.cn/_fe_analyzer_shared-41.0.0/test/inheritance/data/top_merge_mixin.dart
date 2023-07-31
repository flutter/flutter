// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: A:A<T>,Object*/
abstract class A<T> {
  /*member: A.member:T Function()*/
  T member();
}

/*cfe|cfe:builder.class: B:B<T>,Object*/
/*cfe|cfe:builder.member: B.member:T Function()*/
mixin B<T> {
  T member();
}

/*class: D0:A<dynamic>,B<Object?>,D0,Object*/
/*member: D0.member:Object? Function()*/
abstract class D0 extends A<dynamic> with B<Object?> {}

/*class: D1:A<Object?>,B<dynamic>,D1,Object*/
/*member: D1.member:dynamic Function()*/
abstract class D1 extends A<Object?> with B<dynamic> {}

/*class: D2:A<void>,B<Object?>,D2,Object*/
/*member: D2.member:Object? Function()*/
abstract class D2 extends A<void> with B<Object?> {}

/*class: D3:A<Object?>,B<void>,D3,Object*/
/*member: D3.member:void Function()*/
abstract class D3 extends A<Object?> with B<void> {}

/*class: D4:A<void>,B<dynamic>,D4,Object*/
/*member: D4.member:dynamic Function()*/
abstract class D4 extends A<void> with B<dynamic> {}

/*class: D5:A<dynamic>,B<void>,D5,Object*/
/*member: D5.member:void Function()*/
abstract class D5 extends A<dynamic> with B<void> {}

/*class: D6:A<void>,B<void>,D6,Object*/
/*member: D6.member:void Function()*/
abstract class D6 extends A<void> with B<void> {}

/*class: D7:A<dynamic>,B<dynamic>,D7,Object*/
/*member: D7.member:dynamic Function()*/
abstract class D7 extends A<dynamic> with B<dynamic> {}
