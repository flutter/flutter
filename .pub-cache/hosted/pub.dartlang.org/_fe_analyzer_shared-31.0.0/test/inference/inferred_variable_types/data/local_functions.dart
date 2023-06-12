// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

localFunctions() {
  /*Null*/ unrestrictedLocalFunction1(/*dynamic*/ o) {}
  var /*Null Function(dynamic)*/ unrestrictedLocalFunction2 =
      /*Null*/ (/*dynamic*/ o) {};

  /*dynamic*/ arrowReturn1(/*dynamic*/ o) => o;
  var /*dynamic Function(dynamic)*/ arrowReturn2 =
      /*dynamic*/ (/*dynamic*/ o) => o;

  /*dynamic*/ singleReturn1(/*dynamic*/ o) {
    return o;
  }

  var /*dynamic Function(dynamic)*/ singleReturn2 =
      /*dynamic*/ (/*dynamic*/ o) {
    return o;
  };

  /*int*/ typedArrowReturn1() => 1;
  var /*int Function()*/ typedArrowReturn2 = /*int*/ () => 1;

  /*int*/ singleTypedReturn1() {
    return 1;
  }

  var /*int Function()*/ singleTypedReturn2 = /*int*/ () {
    return 1;
  };

  /*int?*/ multipleTypedReturns1(bool condition) {
    if (condition) {
      return 1;
    } else {
      return null;
    }
  }

  var /*int? Function(bool)*/ multipleTypedReturns2 = /*int?*/ (bool
      condition) {
    if (condition) {
      return 1;
    } else {
      return null;
    }
  };

  int Function(String) inferredFromContext = /*int*/ (/*String*/ condition) =>
      condition.length;
}
