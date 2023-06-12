// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";
import "dart:async";

Type typeOf<X>() => X;

/*class: C:A<FutureOr<int?>>,C,Object*/
/*cfe|cfe:builder.member: C.toString:String* Function()**/
/*cfe|cfe:builder.member: C.runtimeType:Type**/
/*cfe|cfe:builder.member: C._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: C.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: C._identityHashCode:int**/
/*cfe|cfe:builder.member: C.hashCode:int**/
/*cfe|cfe:builder.member: C._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: C.==:bool* Function(dynamic)**/
class C extends A<FutureOr<int?>> {
  /*member: C.getType:Type* Function()**/
}

/*class: D:A<FutureOr<int>>,D,Object*/
/*cfe|cfe:builder.member: D.toString:String* Function()**/
/*cfe|cfe:builder.member: D.runtimeType:Type**/
/*cfe|cfe:builder.member: D._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: D.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: D._identityHashCode:int**/
/*cfe|cfe:builder.member: D.hashCode:int**/
/*cfe|cfe:builder.member: D._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: D.==:bool* Function(dynamic)**/
class D extends A<FutureOr<int>> {
  /*member: D.getType:Type* Function()**/
}

/// TODO: Solve CFE / analyzer difference.
/// It looks to me that CFE type of `A` is incorrect.
/// As described in https://github.com/dart-lang/sdk/issues/40553,
/// NNBD_TOP_MERGE(FutureOr<int?>, FutureOr*<int*>) = FutureOr<int?>
/*cfe|cfe:builder.class: E:A<FutureOr<int?>?>,B,C,E,Object*/
/*analyzer.class: E:A<FutureOr<int?>>,B,C,E,Object*/
/*cfe|cfe:builder.member: E.toString:String* Function()**/
/*cfe|cfe:builder.member: E.runtimeType:Type**/
/*cfe|cfe:builder.member: E._simpleInstanceOf:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._instanceOf:bool* Function(dynamic, dynamic, dynamic)**/
/*cfe|cfe:builder.member: E.noSuchMethod:dynamic Function(Invocation*)**/
/*cfe|cfe:builder.member: E._identityHashCode:int**/
/*cfe|cfe:builder.member: E.hashCode:int**/
/*cfe|cfe:builder.member: E._simpleInstanceOfFalse:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E._simpleInstanceOfTrue:bool* Function(dynamic)**/
/*cfe|cfe:builder.member: E.==:bool* Function(dynamic)**/
class E extends B implements C {
  /*member: E.getType:Type* Function()**/
}

main() {
  print(typeOf<FutureOr<int?>>() == E().getType());
  print(typeOf<FutureOr<int>>() == E().getType());
}
