// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void bang_promotes(int? x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNullableTypeVariable<E>(E? x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNonNullableTypeVariable<E>(E x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNullableTypeVariableWithNullableBound<E extends int?>(E? x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNonNullableTypeVariableWithNullableBound<E extends int?>(
    E x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNullableTypeVariableWithNonNullableBound<E extends int>(
    E? x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesNullableFutureInt(FutureOr<int>? x) {
  x!;
  /*nonNullable*/ x;
}

void bang_promotesFutureNullableInt(FutureOr<int?> x) {
  x!;
  x;
}

void bang_promotesNullableFutureNullableInt(FutureOr<int?>? x) {
  x!;
  x;
}
