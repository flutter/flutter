// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {}

class B extends A {}

class C extends B {}

combine_empty(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v;
}

conditional_isNotType(bool b, Object v) {
  if (b ? (v is! int) : (v is! num)) {
    v;
  } else {
    v;
  }
  v;
}

conditional_isType(bool b, Object v) {
  if (b ? (v is int) : (v is num)) {
    v;
  } else {
    v;
  }
  v;
}

isNotType(v) {
  if (v is! String) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}

isNotType_return(v) {
  if (v is! String) return;
  /*String*/ v;
}

isNotType_throw(v) {
  if (v is! String) throw 42;
  /*String*/ v;
}

isType(v) {
  if (v is String) {
    /*String*/ v;
  } else {
    v;
  }
  v;
}

isType_factor_Null(int? v) {
  if (v is Null) {
    /*Null*/ v;
  } else {
    /*int*/ v;
  }
  v;
}

isType_factor_nullable(num? v) {
  if (v is int?) {
    /*int?*/ v;
  } else {
    /*num*/ v;
  }
  v;
}

isType_factor_declaredType(int? v) {
  if (v is int?) {
    v;
  } else {
    // Type promotion never promotes a variable to type `Never`, since that
    // could lead to code being deemed unreachable when in fact it is reachable
    // due to mixed mode unsoundness.  (In this particular case mixed mode
    // unsoundness couldn't cause this "else" block to be reached, but flow
    // analysis isn't smart enough to know that.)
    v;
  }
  v;
}

isType_factor_supertype(int? v) {
  if (v is num?) {
    v;
  } else {
    // Type promotion never promotes a variable to type `Never`, since that
    // could lead to code being deemed unreachable when in fact it is reachable
    // due to mixed mode unsoundness.  (In this particular case mixed mode
    // unsoundness couldn't cause this "else" block to be reached, but flow
    // analysis isn't smart enough to know that.)
    v;
  }
  v;
}

isType_factor_futureOr_future(FutureOr<int> v) {
  if (v is Future<int>) {
    /*Future<int>*/ v;
  } else {
    /*int*/ v;
  }
  v;
}

isType_factor_futureOr_type(FutureOr<int> v) {
  if (v is int) {
    /*int*/ v;
  } else {
    /*Future<int>*/ v;
  }
  v;
}

isType_thenNonBoolean(Object x) {
  if ((x is String) != 3) {
    x;
  }
}

joinIntersectsPromotedTypes(Object a, bool b) {
  if (b) {
    a as A;
    /*A*/ a as C;
  } else {
    a as B;
    /*B*/ a as C;
  }
  /*C*/ a;
}

logicalNot_isType(v) {
  if (!(v is String)) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}

void isNotType_return2(bool b, Object x) {
  if (b) {
    if (x is! String) return;
  }
  x;
}
