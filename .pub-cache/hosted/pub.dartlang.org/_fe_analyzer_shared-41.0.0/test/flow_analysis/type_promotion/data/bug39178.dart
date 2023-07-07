// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f(Object x, bool b) {
  if (x is num) {
    if (/*num*/ x is int) {
      try {
        throw 'foo';
      } catch (e) {
        x = 1.5;
        if (b) throw 'baz';
        x = 0;
      } finally {
        // Note: on entry to the "finally", flow analysis
        // conservatively de-promotes any variables that were assigned
        // earlier in the statement, on the grounds that whatever type
        // they are promoted to now, there's no guarantee that they
        // had that type throughout execution of the try block.  In
        // this particular case that's over-conservative--we could in
        // principle keep the promotion to "num", since the value
        // assigned is compatible with "num").  But it doesn't seem
        // worth the extra analysis cost to do so.
        x;
      }
    }
  }
}

f2(Object x, bool b) {
  if (x is num) {
    if (/*num*/ x is int) {
      try {
        throw 'foo';
      } catch (e) {
        /*int*/ x;
      } finally {
        // x has not been assigned to so the promotion is kept.
        /*int*/ x;
      }
    }
  }
}

f3(Object x, bool b) {
  if (x is num) {
    if (/*num*/ x is int) {
      try {
        throw 'foo';
      } catch (e) {
        /*int*/ x;
      } finally {
        // x has not been assigned to in the try/catch blocks so the promotion
        // is kept here.
        /*int*/ x;
        x = 'foo';
      }
    }
  }
}
