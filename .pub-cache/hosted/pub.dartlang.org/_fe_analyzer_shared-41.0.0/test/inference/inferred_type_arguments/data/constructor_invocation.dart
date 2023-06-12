// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic dyn = null;

class Unbounded<T> {
  Unbounded();
}

class UnboundedArg<T> {
  UnboundedArg(T t);
}

class ExtendsNum<T extends num> {
  ExtendsNum();
}

class ExtendsNumArg<T extends num> {
  ExtendsNumArg(T t);
}

class MultipleArgs<T, U, S> {
  MultipleArgs(T t, S s, U u);
}

staticInvocations() {
  Unbounded/*<dynamic>*/();
  Unbounded<int>();
  var unboundedReturn1 = Unbounded/*<dynamic>*/();
  Unbounded<int> unboundedReturn2 = Unbounded/*<int>*/();
  Unbounded<num> unboundedReturn3 = Unbounded<int>();
  Unbounded unboundedReturn4 = Unbounded/*<dynamic>*/();

  UnboundedArg/*<Null>*/(null);
  UnboundedArg/*<int>*/(0);
  UnboundedArg/*<String>*/("");
  UnboundedArg<num>(0);
  var unboundedReturnArg1 = UnboundedArg/*<int>*/(0);
  var unboundedReturnArg2 = UnboundedArg/*<String>*/("");
  UnboundedArg<num> unboundedReturnArg3 = UnboundedArg/*<num>*/(0);
  UnboundedArg<int> unboundedReturnArg4 = UnboundedArg/*<int>*/(0);
  UnboundedArg<int> unboundedReturnArg5 = UnboundedArg/*<int>*/(0.5);
  UnboundedArg<int> unboundedReturnArg6 = UnboundedArg/*<int>*/("");
  UnboundedArg<int> unboundedReturnArg7 = UnboundedArg<num>(0);
  UnboundedArg unboundedReturnArg8 = UnboundedArg/*<dynamic>*/(0);

  ExtendsNum/*<num>*/();
  ExtendsNum<int>();
  var extendsNumReturn1 = ExtendsNum/*<num>*/();
  ExtendsNum<int> extendsNumReturn2 = ExtendsNum/*<int>*/();
  ExtendsNum<num> extendsNumReturn3 = ExtendsNum<int>();
  ExtendsNum extendsNumReturn4 = ExtendsNum/*<num>*/();

  ExtendsNumArg/*<Null>*/(null);
  ExtendsNumArg/*<int>*/(0);
  ExtendsNumArg/*<String>*/("");
  ExtendsNumArg<num>(0);
  var extendsNumReturnArg1 = ExtendsNumArg/*<int>*/(0);
  var extendsNumReturnArg2 = ExtendsNumArg/*<String>*/("");
  ExtendsNumArg<num> extendsNumReturnArg3 = ExtendsNumArg/*<num>*/(0);
  ExtendsNumArg<int> extendsNumReturnArg4 = ExtendsNumArg/*<int>*/(0);
  ExtendsNumArg<int> extendsNumReturnArg5 = ExtendsNumArg/*<int>*/(0.5);
  ExtendsNumArg<int> extendsNumReturnArg6 = ExtendsNumArg/*<int>*/("");
  ExtendsNumArg<int> extendsNumReturnArg7 = ExtendsNumArg<num>(0);
  ExtendsNumArg extendsNumReturnArg8 = ExtendsNumArg/*<num>*/(0);

  MultipleArgs/*<dynamic,dynamic,dynamic>*/(dyn, dyn, dyn);
  MultipleArgs/*<int,String,bool>*/(0, true, "");
  MultipleArgs<int, bool, String>(0, true, "");
  var multipleArgs1 = MultipleArgs /*analyzer.<dynamic,dynamic,dynamic>*/ ();
  var multipleArgs2 = MultipleArgs/*<int,String,bool>*/(0, true, "");
  MultipleArgs multipleArgs3 =
      MultipleArgs/*<dynamic,dynamic,dynamic>*/(0, true, "");
  MultipleArgs<int, String, bool> multipleArgs4 =
      MultipleArgs/*<int,String,bool>*/(dyn, dyn, dyn);
}
