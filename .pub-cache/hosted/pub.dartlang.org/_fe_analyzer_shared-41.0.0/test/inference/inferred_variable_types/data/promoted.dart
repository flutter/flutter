// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

promoted<T, S extends num>(dynamic d, num n, T t, S s) {
  var /*dynamic*/ unpromotedDynamic = d;
  var /*num*/ unpromotedNum = n;
  var /*T*/ unpromotedUnboundedTypeVariable = t;
  var /*S*/ unpromotedBoundedTypeVariable = s;
  if (d is int) {
    var /*int*/ promotedDynamic = d;
  }
  if (n is int) {
    var /*int*/ promotedInt = n;
  }
  if (t is int) {
    var /*T*/ promotedUnboundedTypeVariable = t;
  }
  if (s is int) {
    var /*S*/ unpromotedBoundedTypeVariable = s;
  }
  if (t is S) {
    var /*T*/ promotedUnboundedTypeVariable = t;
  }
}
