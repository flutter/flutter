// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

notATypeOfInterest(Object x) {
  x = 1;
  x;
}

typeOfInterest_is(Object x) {
  if (x is int) {
  } else {
    x = 1;
    /*int*/ x;
  }
  /*int*/ x;
}

typeOfInterest_is_nullable(Object? x) {
  if (x is int?) {
  } else {
    x = 1;
    /*int*/ x;
  }
  x;
}

typeOfInterest_isNot(Object x) {
  if (x is! int) {
    x = 1;
    /*int*/ x;
  }
  /*int*/ x;
}

typeOfInterest_isNot_nullable(Object? x) {
  if (x is! int?) {
    x = 1;
    /*int*/ x;
  }
  x;
}

typeOfInterest_declaredNullable_exact(int? x) {
  x = 1;
  /*int*/ x;
}

typeOfInterest_declaredNullable_subtype(Object? x) {
  x = 1;
  /*Object*/ x;
}

typeOfInterest_notEqualNull(Object? x) {
  if (x != null) {
  } else {
    x = 1;
    /*Object*/ x;
  }
  /*Object*/ x;
}

typeOfInterest_equalNull(Object? x) {
  if (x == null) {
    x = 1;
    /*Object*/ x;
  }
  /*Object*/ x;
}

typeOfInterest_nullAwareAssignment(Object? x) {
  x ??= 1;
  /*Object*/ x;
}

typeOfInterest_ifNullExpression(Object? x) {
  x ?? (x = 1);
  /*Object*/ x;
}
