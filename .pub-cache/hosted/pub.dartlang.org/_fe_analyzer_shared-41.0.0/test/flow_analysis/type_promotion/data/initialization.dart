// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file exercise "promotable via initialization" part of
// the flow analysis specification.

localVariable() {
  var x;
  x = 1;
  x;
  x = 2.3;
  x;
}

localVariable_null() {
  var x = null;
  x;
}

localVariable_hasInitializer(num a) {
  var x = a;
  x = 1;
  x;
}

localVariable_hasTypeAnnotation() {
  num x;
  x = 1;
  x;
}

localVariable_hasTypeAnnotation_dynamic() {
  dynamic x;
  x = 1;
  x;
}

localVariable_ifElse_differentTypes(bool a) {
  var x;
  if (a) {
    x = 0;
    x;
  } else {
    x = 1.2;
    x;
  }
  x;
}

localVariable_ifElse_sameTypes(bool a) {
  var x;
  if (a) {
    x = 0;
    x;
  } else {
    x = 1;
    x;
  }
  x;
}

localVariable_initialized_nonNull() {
  num? x = 0;
  /*num*/ x;
  x = null;
  x;
}

localVariable_initialized_nonNull_final() {
  final num? x = 0;
  x;
}

localVariable_initialized_promoted_type_var<T>(T t) {
  if (t is num) {
    var x = /*T & num*/ t;
    /*T & num*/ x;
    // Check that it is a type of interest by promoting and then writing to it
    if (/*T & num*/ x is int) {
      /*T & int*/ x;
      x = /*T & num*/ t;
      /*T & num*/ x;
    }
  }
}

localVariable_initialized_unpromoted_type_var<T>(T t) {
  var x = t;
  x;
  // Check that `T & Object` is a type of interest, by promoting and then
  // writing to it
  if (x is int && t is num) {
    /*T & int*/ x;
    x = /*T & num*/ t;
    /*T & Object*/ x;
  }
}

localVariable_initialized_unpromoted_type_var_with_bound<T extends num?>(T t) {
  var x = t;
  x;
  // Check that `T & num` is a type of interest, by promoting and then writing
  // to it
  if (x is int && t is double) {
    /*T & int*/ x;
    x = /*T & double*/ t;
    /*T & num*/ x;
  }
}

localVariable_initialized_promoted_type_var_typed<T>(T t) {
  if (t is num) {
    // This should promote to `T & Object`, because that's the non-nullable
    // version of T, but it shouldn't promote to `T & num`.
    T x = /*T & num*/ t;
    /*T & Object*/ x;
    // Check that `T & Object` is a type of interest by promoting and then
    // writing to it
    if (/*T & Object*/ x is int) {
      /*T & int*/ x;
      x = /*T & num*/ t;
      /*T & Object*/ x;
    }
  }
}

localVariable_initialized_promoted_type_var_final<T>(T t) {
  if (t is num) {
    final x = /*T & num*/ t;
    /*T & num*/ x;
    // Note: it's not observable whether it's a type of interest because we
    // can't write to it again.
  }
}

localVariable_initialized_promoted_type_var_final_typed<T>(T t) {
  if (t is num) {
    final T x = /*T & num*/ t;
    x;
    // Note: it's not observable whether it's a type of interest because we
    // can't write to it again.
  }
}

localVariable_notDefinitelyUnassigned(bool a) {
  var x;
  if (a) {
    x = 1.2;
  }
  x = 1;
  x;
}

localVariable_notDefinitelyUnassigned_hasLocalFunction() {
  var x;

  void f() {
    // Note, no assignment to 'x', but because 'x' is assigned somewhere in
    // the enclosing function, it is not definitely unassigned in 'f'.
    // So, when we join after 'f' declaration, we make 'x' not definitely
    // unassigned in the enclosing function as well.
  }

  f();

  x = 1;
  x;
}

parameter(x) {
  x = 1;
  x;
}

parameterLocal() {
  void f(x) {
    x = 1;
    x;
  }

  f(0);
}
