// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

assignmentDepromotes(Object x) {
  if (x is String) {
    x = 42;
    x;
  }
}

assignmentDepromotes_partial(Object x) {
  if (x is num) {
    if (/*num*/ x is int) {
      x = 42.0;
      /*num*/ x;
    }
  }
}

assignmentDepromotes_partial_nonNull(Object? x) {
  if (x is num?) {
    /*num?*/ x;
    if (/*num?*/ x is int?) {
      /*int?*/ x;
      x = 1.2;
      /*num*/ x;
    }
  }
}

assignmentPreservesPromotion(Object x) {
  if (x is num) {
    x = 42;
    /*num*/ x;
  }
}

compoundAssignmentDepromotes(Object x) {
  if (x is int) {
    /*int*/ x += 0.5;
    x;
  }
}

compoundAssignmentDepromotes_partial(Object x) {
  if (x is num) {
    if (/*num*/ x is int) {
      /*int*/ x += 0.5;
      /*num*/ x;
    }
  }
}

compoundAssignmentPreservesPromotion(Object x) {
  if (x is num) {
    /*num*/ x += 0.5;
    /*num*/ x;
  }
}

nullAwareAssignmentDepromotes(Object x) {
  if (x is int?) {
    x ??= 'foo';
    x;
  }
}

preIncrementDepromotes(Object x) {
  if (x is C) {
    ++ /*C*/ x;
    x;
  }
}

postIncrementDepromotes(Object x) {
  if (x is C) {
    /*C*/ x++;
    x;
  }
}

preDecrementDepromotes(Object x) {
  if (x is C) {
    -- /*C*/ x;
    x;
  }
}

postDecrementDepromotes(Object x) {
  if (x is C) {
    /*C*/ x--;
    x;
  }
}

preIncrementPreservesPromotion(Object x) {
  if (x is int) {
    ++ /*int*/ x;
    /*int*/ x;
  }
}

postIncrementPreservesPromotion(Object x) {
  if (x is int) {
    /*int*/ x++;
    /*int*/ x;
  }
}

preDecrementPreservesPromotion(Object x) {
  if (x is int) {
    -- /*int*/ x;
    /*int*/ x;
  }
}

postDecrementPreservesPromotion(Object x) {
  if (x is int) {
    /*int*/ x--;
    /*int*/ x;
  }
}

class C {
  Object operator +(int i) => 'foo';
  Object operator -(int i) => 'foo';
}
