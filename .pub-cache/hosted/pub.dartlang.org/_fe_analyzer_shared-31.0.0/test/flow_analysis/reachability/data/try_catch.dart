// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void basic() {
  try {
    1;
  } catch (_) {
    2;
  }
  3;
}

void return_body() {
  try {
    1;
    return;
    /*stmt: unreachable*/ 2;
  } catch (_) {
    3;
  }
  4;
}

void return_catch() {
  try {
    1;
  } catch (_) {
    2;
    return;
    /*stmt: unreachable*/ 3;
  }
  4;
}

void return_body2() {
  try {
    1;
    return;
  } catch (_) {
    2;
  } finally {
    3;
  }
  4;
}

/*member: return_bodyCatch:doesNotComplete*/
void return_bodyCatch() {
  try {
    1;
    return;
  } catch (_) {
    2;
    return;
  } finally {
    3;
  }
  /*stmt: unreachable*/ 4;
}

void return_catch2() {
  try {
    1;
  } catch (_) {
    2;
    return;
  } finally {
    3;
  }
  4;
}

/*member: return_body3:doesNotComplete*/
void return_body3() {
  try {
    1;
    return;
  } finally {
    2;
  }
  /*stmt: unreachable*/ 3;
}
