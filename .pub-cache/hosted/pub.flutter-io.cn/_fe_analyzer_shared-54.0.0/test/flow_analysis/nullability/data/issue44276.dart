// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  int? value1;
  int? value2;
}

int? fun() {
  Base? a;
  // if `a` is `null`, then `a?.value1` evaluates to `null`, so the RHS of the
  // `??` will be evaluated.  Therefore, we can't promote `a` to non-nullable in
  // `a?.value2`.
  final b = a?.value1 ?? a?.value2;
  return b;
}
