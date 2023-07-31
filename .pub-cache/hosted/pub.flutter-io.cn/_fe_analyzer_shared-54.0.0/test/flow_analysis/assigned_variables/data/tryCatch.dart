// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: tryCatch:declared={a, b}, assigned={a, b}*/
tryCatch(int a, int b) {
  /*declared={d}, assigned={a, b}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } on String {
    // Note: flow analysis doesn't need to track variables assigned, captured,
    // or declared inside of catch blocks.  So we don't create an
    // AssignedVariables node for this catch block, and consequently the
    // assignment to `b` and declaration of `d` are considered to belong to the
    // enclosing function.
    b = 0;
    var d;
  }
}

/*member: catchClause:declared={a, b}, assigned={a, b}*/
catchClause(int a, int b) {
  /*declared={d, e}, assigned={a, b}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } catch (e) {
    b = 0;
    var d;
  }
}

/*member: onCatch:declared={a, b}, assigned={a, b}*/
onCatch(int a, int b) {
  /*declared={d, e}, assigned={a, b}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } on String catch (e) {
    b = 0;
    var d;
  }
}

/*member: catchStackTrace:declared={a, b}, assigned={a, b}*/
catchStackTrace(int a, int b) {
  /*declared={d, e, st}, assigned={a, b}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } catch (e, st) {
    b = 0;
    var d;
  }
}

/*member: onCatchStackTrace:declared={a, b}, assigned={a, b}*/
onCatchStackTrace(int a, int b) {
  /*declared={d, e, st}, assigned={a, b}*/ try /*declared={c}, assigned={a}*/ {
    a = 0;
    var c;
  } on String catch (e, st) {
    b = 0;
    var d;
  }
}
