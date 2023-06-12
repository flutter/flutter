// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum MyEnum { a, b }

void case_never_completes(bool b, int i) {
  switch (i) {
    case 1:
      1;
      if (b) {
        return;
      } else {
        return;
      }
      /*stmt: unreachable*/ 2;
  }
  3;
}

void case_falls_through_end(int i) {
  switch (i) {
    case 1:
      1;
  }
  2;
}

/*member: all_cases_exit:doesNotComplete*/
void all_cases_exit(int i) {
  switch (i) {
    case 1:
      return;
    default:
      return;
  }
  /*stmt: unreachable*/ 1;
}

/*member: enum_no_default:doesNotComplete*/
void enum_no_default(MyEnum e) {
  switch (e) {
    case MyEnum.a:
      return;
    case MyEnum.b:
      return;
  }
  /*stmt: unreachable*/ 1;
}
