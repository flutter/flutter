// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

typedef Typedef();
typedef GenericTypedef<T> = void Function(T);
typedef GenericFunctionTypedef = void Function<T>(T);
typedef TypedefWithFutureOr = void Function<T>(FutureOr<T>);

const typedef = /*cfe.TypeLiteral(dynamic Function())*/ Typedef;
const genericTypedef =
    /*cfe.TypeLiteral(void Function(dynamic))*/ GenericTypedef;
const genericFunctionTypedef =
    /*cfe.TypeLiteral(void Function<T>(T))*/ GenericFunctionTypedef;
const typedefWithFutureOr =
    /*cfe.TypeLiteral(void Function<T>(FutureOr<T>))*/ TypedefWithFutureOr;
const futureOr = /*cfe.TypeLiteral(FutureOr<dynamic>)*/ FutureOr;
const null_ = /*cfe.TypeLiteral(Null)*/ Null;

main() {
  print(
      /*analyzer.TypeLiteral(dynamic Function()*)*/
      /*cfe.TypeLiteral(dynamic Function())*/
      /*dart2js.TypeLiteral(()->dynamic)*/
      typedef);

  print(
      /*analyzer.TypeLiteral(void Function(dynamic)*)*/
      /*cfe.TypeLiteral(void Function(dynamic))*/
      /*dart2js.TypeLiteral((dynamic)->void)*/
      genericTypedef);

  print(
      /*analyzer.TypeLiteral(void Function<T>(T*)*)*/
      /*cfe.TypeLiteral(void Function<T>(T))*/
      /*dart2js.TypeLiteral((0)->void)*/
      genericFunctionTypedef);

  print(
      /*analyzer.TypeLiteral(void Function<T>(FutureOr<T*>*)*)*/
      /*cfe.TypeLiteral(void Function<T>(FutureOr<T>))*/
      /*dart2js.TypeLiteral((FutureOr<0>)->void)*/
      typedefWithFutureOr);

  print(
      /*analyzer.TypeLiteral(FutureOr<dynamic>*)*/
      /*cfe.TypeLiteral(FutureOr<dynamic>)*/
      /*dart2js.TypeLiteral(dynamic)*/
      futureOr);

  print(
      /*analyzer.TypeLiteral(Null*)*/
      /*cfe|dart2js.TypeLiteral(Null)*/
      null_);
}
