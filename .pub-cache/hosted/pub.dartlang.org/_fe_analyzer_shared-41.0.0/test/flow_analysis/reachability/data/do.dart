// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void do_false() {
  do {
    1;
  } while (false);
  2;
}

/*member: do_true:doesNotComplete*/
void do_true() {
  do {
    1;
  } while (true);
  /*stmt: unreachable*/ 2;
}
