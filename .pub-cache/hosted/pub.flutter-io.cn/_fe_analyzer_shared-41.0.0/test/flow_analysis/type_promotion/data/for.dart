// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Object g() => Null;

void for_declaredVar() {
  for (Object x = g(); x is int; x = g()) {
    /*int*/ x;
  }
}

void for_outerIsType(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      /*String*/ x;
    }
    /*String*/ x;
  }
}

void for_outerIsType_loopAssigned_body(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x;
      x = 42;
    }
    x;
  }
}

void for_outerIsType_loopAssigned_body_emptyCondition(bool b, Object x) {
  if (x is String) {
    for (;;) {
      if (!b) break;
      x;
      x = 42;
    }
    x;
  }
}

void for_outerIsType_loopAssigned_condition(Object x) {
  if (x is String) {
    for (; (x = 42) > 0;) {
      x;
    }
    x;
  }
}

void for_outerIsType_loopAssigned_updaters(bool b, Object x) {
  if (x is String) {
    for (; b; x = 42) {
      x;
    }
    x;
  }
}

void for_outerIsType_loopAssigned_updaters_emptyCondition(bool b, Object x) {
  if (x is String) {
    for (;; x = 42) {
      if (!b) break;
      x;
    }
    x;
  }
}

void forEach_outerIsType_loopAssigned(Object x) {
  if (x is String) {
    for (var _ in [0, 1, 2]) {
      x;
      x = 42;
    }
    x;
  }
}

void collection_for_declaredVar() {
  [for (Object x = g(); x is int; x = g()) /*int*/ x ];
}

void collection_for_outerIsType(bool b, Object x) {
  if (x is String) {
    [for (; b;) /*String*/ x ];
    /*String*/ x;
  }
}

void collection_for_outerIsType_loopAssigned_body(bool b, Object x) {
  if (x is String) {
    [
      for (; b;) [x, (x = 42)]
    ];
    x;
  }
}

void collection_for_outerIsType_loopAssigned_body_emptyCondition(Object x) {
  if (x is String) {
    [
      for (;;) [x, (x = 42)]
    ];
    x;
  }
}

void collection_for_outerIsType_loopAssigned_condition(Object x) {
  if (x is String) {
    [for (; (x = 42) > 0;) x];
    x;
  }
}

void collection_for_outerIsType_loopAssigned_updaters(bool b, Object x) {
  if (x is String) {
    [for (; b; x = 42) x];
    x;
  }
}

void collection_for_outerIsType_loopAssigned_updaters_emptyCondition(Object x) {
  if (x is String) {
    [for (;; x = 42) x];
    x;
  }
}

void collection_forEach_outerIsType_loopAssigned(Object x) {
  if (x is String) {
    [
      for (var _ in [0, 1, 2]) [x, (x = 42)]
    ];
    x;
  }
}

void assign_var_declared_in_loop() {
  for (int x = 0; x < 10; x++) {
    bool b = true;
    b = false;
  }
}

void forEach_noDemotion(Object? x, List<int> y) {
  if (x is int) {
    /*int*/ x;
    for (x in y) {
      /*int*/ x;
    }
    /*int*/ x;
  }
}

void forEach_partialDemotion(Object? x, List<num> y) {
  if (x is num) {
    if (/*num*/ x is int) {
      /*int*/ x;
      for (x in y) {
        /*num*/ x;
      }
      /*num*/ x;
    }
  }
}

void collection_forEach_noDemotion(Object? x, List<int> y) {
  if (x is int) {
    /*int*/ x;
    [for (x in y) /*int*/ x ];
    /*int*/ x;
  }
}

void collection_forEach_partialDemotion(Object? x, List<num> y) {
  if (x is num) {
    if (/*num*/ x is int) {
      /*int*/ x;
      [for (x in y) /*num*/ x ];
      /*num*/ x;
    }
  }
}
