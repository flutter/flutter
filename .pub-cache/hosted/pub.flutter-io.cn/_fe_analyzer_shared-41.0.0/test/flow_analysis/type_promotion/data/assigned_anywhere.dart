// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that for various ways of defining functions, we properly
// determine which set of variables are potentially assigned anywhere within the
// function, and suppress promotions inside closures.

bool f(Object x) => true;

topLevel_function(Object x, Object y) {
  if (x is int && y is int) {
    /*int*/ x;
    /*int*/ y;
    () {
      /*int*/ x;
      y;
    };
  }
  y = 'foo';
}

topLevel_function_arrow(Object x, Object y) => (x is int && y is int)
    ? [
        /*int*/ x,
        /*int*/ y,
        () {
          /*int*/ x;
          y;
        }
      ]
    : (y = 'foo');

void topLevel_setter(Object x) {
  Object y = f(0);
  if (x is int && y is int) {
    /*int*/ x;
    /*int*/ y;
    () {
      /*int*/ x;
      y;
    };
  }
  y = 'foo';
}

void topLevel_setter_arrow(Object y) => (y is int)
    ? [
        /*int*/ y,
        () {
          y;
        }
      ]
    : (y = 'foo');

get topLevel_getter {
  Object x = f(0);
  Object y = f(0);
  if (x is int && y is int) {
    /*int*/ x;
    /*int*/ y;
    () {
      /*int*/ x;
      y;
    };
  }
  y = 'foo';
  return 0;
}

class C {
  C(Object x);

  C.constructor(Object x, Object y) {
    if (x is int && y is int) {
      /*int*/ x;
      /*int*/ y;
      () {
        /*int*/ x;
        y;
      };
    }
    y = 'foo';
  }

  factory C.constructor_arrow(Object x, Object y) => C((x is int && y is int)
      ? [
          /*int*/ x,
          /*int*/ y,
          () {
            /*int*/ x;
            y;
          }
        ]
      : (y = 'foo'));

  C.constructor_semicolon(Object x, Object y)
      : assert(f((x is int && y is int)
            ? [
                /*int*/ x,
                /*int*/ y,
                () {
                  /*int*/ x;
                  y;
                }
              ]
            : (y = 'foo')));

  method(Object x, Object y) {
    if (x is int && y is int) {
      /*int*/ x;
      /*int*/ y;
      () {
        /*int*/ x;
        y;
      };
    }
    y = 'foo';
  }

  method_arrow(Object x, Object y) => (x is int && y is int)
      ? [
          /*int*/ x,
          /*int*/ y,
          () {
            /*int*/ x;
            y;
          }
        ]
      : (y = 'foo');

  void setter(Object x) {
    Object y = f(0);
    if (x is int && y is int) {
      /*int*/ x;
      /*int*/ y;
      () {
        /*int*/ x;
        y;
      };
    }
    y = 'foo';
  }

  void setter_arrow(Object y) => (y is int)
      ? [
          /*int*/ y,
          () {
            y;
          }
        ]
      : (y = 'foo');

  get getter {
    Object x = f(0);
    Object y = f(0);
    if (x is int && y is int) {
      /*int*/ x;
      /*int*/ y;
      () {
        /*int*/ x;
        y;
      };
    }
    y = 'foo';
    return 0;
  }
}
