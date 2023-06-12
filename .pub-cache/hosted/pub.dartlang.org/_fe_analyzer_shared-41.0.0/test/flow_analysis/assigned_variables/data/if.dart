// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that `if` statements and collection elements are annotated
// with the variables written in their "then" branches.  This is needed for
// legacy type promotion, to ensure that an assignment in the "then" branch
// defeats promotion.

/*member: ifThenStatement:declared={a, b, c}, read={a, c}, assigned={b}*/
ifThenStatement(bool a, bool b, bool c) {
  /*read={c}, assigned={b}*/ if (a) b = c;
}

/*member: ifThenElseStatement:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
ifThenElseStatement(bool a, bool b, bool c, bool d, bool e) {
  /*read={c}, assigned={b}*/ if (a)
    b = c;
  else
    d = e;
}

/*member: ifThenListElement:declared={a, b, c}, read={a, c}, assigned={b}*/
ifThenListElement(bool a, bool b, bool c) {
  [/*read={c}, assigned={b}*/ if (a) b = c];
}

/*member: ifThenElseListElement:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
ifThenElseListElement(bool a, bool b, bool c, bool d, bool e) {
  [/*read={c}, assigned={b}*/ if (a) b = c else d = e];
}

/*member: ifThenSetElement:declared={a, b, c}, read={a, c}, assigned={b}*/
ifThenSetElement(bool a, bool b, bool c) {
  ({/*read={c}, assigned={b}*/ if (a) b = c});
}

/*member: ifThenElseSetElement:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
ifThenElseSetElement(bool a, bool b, bool c, bool d, bool e) {
  ({/*read={c}, assigned={b}*/ if (a) b = c else d = e});
}

/*member: ifThenMapKey:declared={a, b, c}, read={a, c}, assigned={b}*/
ifThenMapKey(bool a, bool b, bool c) {
  ({/*read={c}, assigned={b}*/ if (a) b = c: null});
}

/*member: ifThenElseMapKey:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
ifThenElseMapKey(bool a, bool b, bool c, bool d, bool e) {
  ({/*read={c}, assigned={b}*/ if (a) b = c: null else d = e: null});
}

/*member: ifThenMapValue:declared={a, b, c}, read={a, c}, assigned={b}*/
ifThenMapValue(bool a, bool b, bool c) {
  ({/*read={c}, assigned={b}*/ if (a) null: b = c});
}

/*member: ifThenElseMapValue:declared={a, b, c, d, e}, read={a, c, e}, assigned={b, d}*/
ifThenElseMapValue(bool a, bool b, bool c, bool d, bool e) {
  ({/*read={c}, assigned={b}*/ if (a) null: b = c else null: d = e});
}
