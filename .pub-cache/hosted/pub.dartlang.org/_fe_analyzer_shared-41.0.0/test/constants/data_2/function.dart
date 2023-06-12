// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

T method1<T>(T t) => t;
Map<T, S> method2<T, S>(T t, S s) => {t: s};

const function0 = /*cfe.Function(method1)*/ method1;

const int Function(int) instantiation0 =
    /*cfe.Instantiation(method1<int>)*/ method1;

const Map<String, int> Function(String, int) instantiation1 =
    /*cfe.Instantiation(method2<String,int>)*/ method2;

main() {
  print(
      /*cfe|dart2js.Function(method1)*/
      /*analyzer.Function(method1,type=T* Function<T>(T*)*)*/
      function0);
  print(
      /*cfe.Instantiation(method1<int>)*/
      /*dart2js.Instantiation(method1<int*>)*/
      /*analyzer.Function(method1,type=int* Function(int*)*)*/
      instantiation0);
  print(
      /*cfe.Instantiation(method2<String,int>)*/
      /*dart2js.Instantiation(method2<String*,int*>)*/
      /*analyzer.Function(method2,type=Map<String*, int*>* Function(String*, int*)*)*/
      instantiation1);
}
