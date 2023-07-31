// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: hasReturn:doesNotComplete*/
int hasReturn() {
  return 42;
}

void noReturn() {
  1;
}

/*member: hasThrow:doesNotComplete*/
int hasThrow() {
  throw 42;
}
