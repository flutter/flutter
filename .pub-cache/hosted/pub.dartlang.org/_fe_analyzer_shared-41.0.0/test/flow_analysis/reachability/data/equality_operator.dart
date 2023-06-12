// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void nullValue(Null x) {
  if (x == null) {
    1;
  } else /*unreachable*/ {
    /*stmt: unreachable*/ 2;
  }
}

void neverQuestionValue(Never? x) {
  if (x == null) {
    1;
  } else /*unreachable*/ {
    /*stmt: unreachable*/ 2;
  }
}

void dynamicValue(dynamic x) {
  if (x == null) {
    1;
  } else {
    2;
  }
}

void nullableValue(int? x) {
  if (x == null) {
    1;
  } else {
    2;
  }
}

void nonNullableValue(int x) {
  if (x == null) {
    // Reachable since the value of x might come from legacy code
    1;
  } else {
    2;
  }
}

void potentiallyNullableTypeVar_noBound<T>(T x) {
  if (x == null) {
    1;
  } else {
    2;
  }
}

void potentiallyNullableTypeVar_dynamicBound<T extends dynamic>(T x) {
  if (x == null) {
    1;
  } else {
    2;
  }
}

void potentiallyNullableTypeVar_nullableBound<T extends Object?>(T x) {
  if (x == null) {
    1;
  } else {
    2;
  }
}

void nonNullableTypeVar<T extends Object>(T x) {
  if (x == null) {
    // Reachable since the value of x might come from legacy code
    1;
  } else {
    2;
  }
}

void nullTypeVar<T extends Null>(T x) {
  if (x == null) {
    1;
  } else /*unreachable*/ {
    /*stmt: unreachable*/ 2;
  }
}
