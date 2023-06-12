// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void top_level_function_call(bool b) {
  if (b) {
    topLevelFunction();
    /*stmt: unreachable*/ 0;
  }
}

void method_call(bool b, C c) {
  if (b) {
    c.method();
    /*stmt: unreachable*/ 0;
  }
}

void static_method_call(bool b) {
  if (b) {
    C.staticMethod();
    /*stmt: unreachable*/ 0;
  }
}

void simple_getter_call(bool b, C c) {
  if (b) {
    c.getter;
    /*stmt: unreachable*/ 0;
  }
}

void static_getter_call(bool b) {
  if (b) {
    C.staticGetter;
    /*stmt: unreachable*/ 0;
  }
}

void complex_getter_call(bool b1, bool b2, C c) {
  if (b1) {
    (b2 ? c : c).getter;
    /*stmt: unreachable*/ 0;
  }
}

void binary_operation(bool b, C c) {
  if (b) {
    c + 1;
    /*stmt: unreachable*/ 0;
  }
}

void is_expression(bool b, dynamic d) {
  if (b) {
    topLevelFunction() is int;
    /*stmt: unreachable*/ 0;
  }
}

void as_subexpression(bool b) {
  if (b) {
    topLevelFunction() as Never;
    /*stmt: unreachable*/ 0;
  }
}

void as_expression(bool b, dynamic d) {
  if (b) {
    d as Never;
    /*stmt: unreachable*/ 0;
  }
}

void assignment_rhs(bool b, Never n, Object x) {
  if (b) {
    x = n;
    /*stmt: unreachable*/ 0;
  }
}

void initialization(bool b, Never n) {
  if (b) {
    var x = n;
    /*stmt: unreachable*/ 0;
  }
}

void conditional_condition(bool b) {
  if (b) {
    topLevelFunction() ? /*unreachable*/ 0 : /*unreachable*/ 1;
    /*stmt: unreachable*/ 0;
  }
}

void conditional_then_else(bool b1, bool b2) {
  if (b1) {
    b2 ? topLevelFunction() : topLevelFunction();
    /*stmt: unreachable*/ 0;
  }
}

Future await_expression(bool b) async {
  if (b) {
    await topLevelFunction();
    /*stmt: unreachable*/ 0;
  }
}

void invocation(bool b, Never Function() f) {
  if (b) {
    f();
    /*stmt: unreachable*/ 0;
  }
}

void invocation_argument(bool b, C c) {
  if (b) {
    c.methodTakingArgument(topLevelFunction());
    /*stmt: unreachable*/ 0;
  }
}

void invocation_named_argument(bool b, C c) {
  if (b) {
    c.methodTakingNamedArgument(arg: topLevelFunction());
    /*stmt: unreachable*/ 0;
  }
}

void index_expression(bool b, C c) {
  if (b) {
    c[0];
    /*stmt: unreachable*/ 0;
  }
}

void unary_expression(bool b, C c) {
  if (b) {
    -c;
    /*stmt: unreachable*/ 0;
  }
}

void cascade_method_call(bool b, C c) {
  if (b) {
    c..method();
    /*stmt: unreachable*/ 0;
  }
}

void cascade_getter_call(bool b, C c) {
  if (b) {
    c..getter;
    /*stmt: unreachable*/ 0;
  }
}

/*member: topLevelFunction:doesNotComplete*/
Never topLevelFunction() => throw 'foo';

class C {
  final dynamic field1;
  final dynamic field2;

  /*member: C.method:doesNotComplete*/
  Never method() => throw 'foo';

  /*member: C.staticMethod:doesNotComplete*/
  static Never staticMethod() => throw 'foo';

  void methodTakingArgument(arg) {}
  void methodTakingNamedArgument({arg}) {}

  /*member: C.getter:doesNotComplete*/
  Never get getter => throw 'foo';

  /*member: C.staticGetter:doesNotComplete*/
  static Never get staticGetter => throw 'foo';

  /*member: C.+:doesNotComplete*/
  Never operator +(other) => throw 'foo';

  /*member: C.[]:doesNotComplete*/
  Never operator [](other) => throw 'foo';

  /*member: C.unary-:doesNotComplete*/
  Never operator -() => throw 'foo';

  /*member: C.constructor_initializer:doesNotComplete*/
  C.constructor_initializer()
      : field1 = topLevelFunction(),
        field2 = /*unreachable*/ 0 /*unreachable*/ {}

  void local_getter(bool b) {
    if (b) {
      getter;
      /*stmt: unreachable*/ 0;
    }
  }
}
