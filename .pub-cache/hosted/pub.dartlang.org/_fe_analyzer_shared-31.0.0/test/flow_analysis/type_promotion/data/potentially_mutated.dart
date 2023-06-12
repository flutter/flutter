// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

potentiallyMutatedInClosure(Object x) {
  localFunction() {
    x = 42;
  }

  if (x is String) {
    localFunction();
    x;
  }
}

potentiallyMutatedInScope(Object x) {
  if (x is String) {
    /*String*/ x;
  }

  x = 42;
}
