// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test verifies that various constructs involving an expression of type
/// `Never` are properly treated by flow analysis as belonging to unreachable
/// code paths.

/*member: asExpression:doesNotComplete*/
void asExpression(int i) {
  i as Never;
  /*stmt: unreachable*/ 1;
}

/*member: ifNullExpression:doesNotComplete*/
void ifNullExpression(Null Function() f) {
  f() ?? (throw '');
  // Since `f()` has static type `Null`, it must always evaluate to `null`,
  // hence the shortcut branch of `f() ?? throw ''` is unreachable.  This means
  // that the code path after the whole expression `f() ?? throw ''` should be
  // unreachable.
  /*stmt: unreachable*/ 1;
}

/*member: ifNullAssignment:doesNotComplete*/
void ifNullAssignment(int? x, Null n) {
  n ??= throw '';
  // Since `n` has static type `Null`, it must always be `null`, hence the
  // shortcut branch of `n ??= throw ''` is unreachable.  This means that the
  // code path after the whole expression `n ??= throw ''` should be
  // unreachable.
  /*stmt: unreachable*/ 1;
}

void ifExpression(Object? Function() f) {
  if (f() is Never) /*unreachable*/ {
    /*stmt: unreachable*/ 1;
  } else {
    2;
  }
}

/*member: nonNullAssert:doesNotComplete*/
void nonNullAssert(Null Function() f) {
  f()!;
  // Since `f()` has static type `Null`, it must always evaluate to `null`,
  // hence the non-null assertion always fails.  This means that the code path
  // after the whole expression `f()!` should be unreachable.
  /*stmt: unreachable*/ 1;
}

void nullAwareAccess(Null Function() f, Object? Function() g) {
  f()?.extensionMethod(/*unreachable*/ 1);
  g()?.extensionMethod(2);
}

extension on Object? {
  void extensionMethod(Object? o) {}
}
