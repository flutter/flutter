// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String method() => '';
T genericMethod<T>() => throw '';
T boundedGenericMethod<T extends num>() => throw '';

test() {
  var /*dynamic*/ noInitializer;
  var /*int*/ intLiteral = 0;
  var /*String*/ methodCall = method();
  var /*dynamic*/ genericMethodCall1 = genericMethod();
  var /*int*/ genericMethodCall2 = genericMethod<int>();
  var /*num*/ genericMethodCall3 = boundedGenericMethod();
  var /*int*/ genericMethodCall4 = boundedGenericMethod<int>();
}
