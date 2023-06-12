// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method1:doesNotComplete*/
void method1() {
  var local;
  try {
    local = 0;
    return;
  } finally {
    print(local);
  }
  /*stmt: unreachable*/ local;
}

/*member: method2:doesNotComplete*/
void method2() {
  var local;
  try {
    local = 0;
    return;
  } catch (e) {
    local = 42;
    rethrow;
  } finally {
    print(local);
  }
  /*stmt: unreachable*/ local;
}

void method3() {
  var local;
  try {
    local = 0;
  } catch (e) {
    local = 42;
    rethrow;
  } finally {
    print(local);
  }
  local;
}

void method4() {
  var local;
  try {
    print(local);
  } catch (e) {
    local = 42;
    rethrow;
  } finally {
    local = 0;
  }
  local;
}
