// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  void unboundedUnused<T>() {}

  void unboundedArg<T>(T t) {}

  T unboundedReturn<T>() => throw '';

  T unboundedReturnArg<T>(T t) => t;

  void extendsNumUnused<T extends num>() {}

  void extendsNumArg<T extends num>(T t) {}

  T extendsNumReturn<T extends num>() => throw '';

  T extendsNumReturnArg<T extends num>(T t) => t;

  void multipleArgs<T, U, S>(T t, S s, U u) {}

  instanceInvocations() {
    unboundedUnused/*<dynamic>*/();
    unboundedUnused<int>();

    unboundedArg/*<Null>*/(null);
    unboundedArg/*<int>*/(0);
    unboundedArg/*<String>*/("");
    unboundedArg<num>(0);

    unboundedReturn/*<dynamic>*/();
    unboundedReturn<int>();
    var unboundedReturn1 = unboundedReturn/*<dynamic>*/();
    int unboundedReturn2 = unboundedReturn/*<int>*/();
    num unboundedReturn3 = unboundedReturn<int>();

    unboundedReturnArg/*<Null>*/(null);
    unboundedReturnArg/*<int>*/(0);
    unboundedReturnArg/*<String>*/("");
    unboundedReturnArg<num>(0);
    var unboundedReturnArg1 = unboundedReturnArg/*<int>*/(0);
    var unboundedReturnArg2 = unboundedReturnArg/*<String>*/("");
    num unboundedReturnArg3 = unboundedReturnArg/*<num>*/(0);
    int unboundedReturnArg4 = unboundedReturnArg/*<int>*/(0);
    int unboundedReturnArg5 = unboundedReturnArg/*<int>*/(0.5);
    int unboundedReturnArg6 = unboundedReturnArg/*<int>*/("");
    int unboundedReturnArg7 = unboundedReturnArg<num>(0);

    extendsNumUnused/*<num>*/();
    extendsNumUnused<int>();

    extendsNumArg/*<Null>*/(null);
    extendsNumArg/*<int>*/(0);
    extendsNumArg/*<String>*/("");
    extendsNumArg<num>(0);

    extendsNumReturn/*<num>*/();
    extendsNumReturn<int>();
    var extendsNumReturn1 = extendsNumReturn/*<num>*/();
    int extendsNumReturn2 = extendsNumReturn/*<int>*/();
    num extendsNumReturn3 = extendsNumReturn<int>();

    extendsNumReturnArg/*<Null>*/(null);
    extendsNumReturnArg/*<int>*/(0);
    extendsNumReturnArg/*<String>*/("");
    extendsNumReturnArg<num>(0);
    var extendsNumReturnArg1 = extendsNumReturnArg/*<int>*/(0);
    var extendsNumReturnArg2 = extendsNumReturnArg/*<String>*/("");
    num extendsNumReturnArg3 = extendsNumReturnArg/*<num>*/(0);
    int extendsNumReturnArg4 = extendsNumReturnArg/*<int>*/(0);
    int extendsNumReturnArg5 = extendsNumReturnArg/*<int>*/(0.5);
    int extendsNumReturnArg6 = extendsNumReturnArg/*<int>*/("");
    int extendsNumReturnArg7 = extendsNumReturnArg<num>(0);

    multipleArgs/*<dynamic,dynamic,dynamic>*/();
    multipleArgs/*<int,String,bool>*/(0, true, "");
    multipleArgs<int, bool, String>(0, true, "");
  }
}
