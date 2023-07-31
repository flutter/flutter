// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T f<T>(T x, void callback()) {
  callback();
  return x;
}

doLoop(Object a, Object b, Object c) {
  do {
    if (a is int) a;
    if (b is int) b;
    if (c is int) /*int*/ c;
    f(0, () {
      a = '';
    });
  } while (f(true, () {
    b = '';
  }));
  f(0, () {
    c = '';
  });
}

forLoop(Object a, Object b, Object c, Object d, Object e) {
  for (var x = f(0, () {
    a = '';
  });
      f(true, () {
    b = '';
  });
      f(0, () {
    c = '';
  })) {
    if (a is int) a;
    if (b is int) b;
    if (c is int) c;
    if (d is int) d;
    if (e is int) /*int*/ e;
    f(0, () {
      d = '';
    });
  }
  f(0, () {
    e = '';
  });
}

forEachLoop(Object a, Object b, Object c) {
  for (var x in f([], () {
    a = '';
  })) {
    if (a is int) a;
    if (b is int) b;
    if (c is int) /*int*/ c;
    f(0, () {
      b = '';
    });
  }
  f(0, () {
    c = '';
  });
}

forElement(Object a, Object b, Object c, Object d, Object e) {
  [
    for (var x = f(0, () {
      a = '';
    });
        f(true, () {
      b = '';
    });
        f(0, () {
      c = '';
    }))
      [
        a is int ? a : null,
        b is int ? b : null,
        c is int ? c : null,
        d is int ? d : null,
        e is int ? /*int*/ e : null,
        f(0, () {
          d = '';
        })
      ]
  ];
  f(0, () {
    e = '';
  });
}

forEachElement(Object a, Object b, Object c) {
  [
    for (var x in () {
      a = '';
      return [];
    }())
      [
        a is int ? a : null,
        b is int ? b : null,
        c is int ? /*int*/ c : null,
        f(0, () {
          b = '';
        })
      ]
  ];
  f(0, () {
    c = '';
  });
}

switchWithoutLabels(Object a, Object b, Object c) {
  switch (f(0, () {
    a = '';
  })) {
    case 0:
      if (a is int) a;
      if (b is int) /*int*/ b;
      if (c is int) /*int*/ c;
      f(0, () {
        b = '';
      });
      break;
  }
  f(0, () {
    c = '';
  });
}

switchWithLabels(Object a, Object b, Object c) {
  switch (f(0, () {
    a = '';
  })) {
    L:
    case 0:
      if (a is int) a;
      if (b is int) b;
      if (c is int) /*int*/ c;
      f(0, () {
        b = '';
      });
      break;
  }
  f(0, () {
    c = '';
  });
}

tryCatch(Object a, Object b, Object c) {
  try {
    if (a is int) /*int*/ a;
    if (b is int) /*int*/ b;
    if (c is int) /*int*/ c;
    f(0, () {
      a = '';
    });
    return;
  } catch (_) {
    if (a is int) a;
    if (b is int) /*int*/ b;
    if (c is int) /*int*/ c;
    f(0, () {
      b = '';
    });
  }
  if (a is int) a;
  if (b is int) b;
  if (c is int) /*int*/ c;
  f(0, () {
    c = '';
  });
}

tryFinally(Object a, Object b, Object c) {
  try {
    if (a is int) /*int*/ a;
    if (b is int) /*int*/ b;
    if (c is int) /*int*/ c;
    f(0, () {
      a = '';
    });
  } finally {
    if (a is int) a;
    if (b is int) /*int*/ b;
    if (c is int) /*int*/ c;
    f(0, () {
      b = '';
    });
  }
  if (a is int) a;
  if (b is int) b;
  if (c is int) /*int*/ c;
  f(0, () {
    c = '';
  });
}

whileLoop(Object a, Object b, Object c) {
  while (f(true, () {
    a = '';
  })) {
    if (a is int) a;
    if (b is int) b;
    if (c is int) /*int*/ c;
    f(0, () {
      b = '';
    });
  }
  f(0, () {
    c = '';
  });
}

localFunction(Object a, Object b, Object c) {
  if (a is! int) return;
  if (b is! int) return;
  if (c is! int) return;
  /*int*/ a;
  /*int*/ b;
  /*int*/ c;
  foo() {
    /*int*/ a;
    b;
    c;
    if (b is int) /*int*/ b;
    if (c is int) c;
  }

  b = '';
  /*int*/ a;
  b;
  /*int*/ c;
  if (b is int) /*int*/ b;
  bar() {
    /*int*/ a;
    b;
    c;
    if (b is int) /*int*/ b;
    if (c is int) c;
    c = '';
  }

  /*int*/ a;
  b;
  c;
  if (b is int) /*int*/ b;
  if (c is int) c;
}

closure(Object a, Object b, Object c) {
  if (a is! int) return;
  if (b is! int) return;
  if (c is! int) return;
  /*int*/ a;
  /*int*/ b;
  /*int*/ c;
  f(0, () {
    /*int*/ a;
    b;
    c;
    if (b is int) /*int*/ b;
    if (c is int) c;
  });
  b = '';
  /*int*/ a;
  b;
  /*int*/ c;
  if (b is int) /*int*/ b;
  f(0, () {
    /*int*/ a;
    b;
    c;
    if (b is int) /*int*/ b;
    if (c is int) c;
    c = '';
  });
  /*int*/ a;
  b;
  c;
  if (b is int) /*int*/ b;
  if (c is int) c;
}
