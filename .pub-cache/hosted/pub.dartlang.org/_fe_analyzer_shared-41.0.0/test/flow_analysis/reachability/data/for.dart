// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: condition_true:doesNotComplete*/
void condition_true() {
  for (; true;) {
    1;
  }
  /*stmt: unreachable*/ 2;
}

/*member: condition_true_implicit:doesNotComplete*/
void condition_true_implicit() {
  for (;;) {
    1;
  }
  /*stmt: unreachable*/ 2;
}

void forEach() {
  for (var _ in [0, 1, 2]) {
    1;
    return;
  }
  2;
}

/*member: collection_condition_true:doesNotComplete*/
void collection_condition_true() {
  [for (; true;) 1];
  /*stmt: unreachable*/ 2;
}

/*member: collection_condition_true_implicit:doesNotComplete*/
void collection_condition_true_implicit() {
  [for (;;) 1];
  /*stmt: unreachable*/ 2;
}
