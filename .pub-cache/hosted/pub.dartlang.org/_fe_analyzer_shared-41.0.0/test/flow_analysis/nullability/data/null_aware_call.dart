// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C method(dynamic value) => this;
  C Function(dynamic) get functionGetter => (_) => this;
}

void methodCall(C? c) {
  c?.method(/*nonNullable*/ c);
}

void functionGetterCall(C? c) {
  c?.functionGetter(/*nonNullable*/ c);
}

void methodCall_nullShorting(C? c) {
  c?.method(/*nonNullable*/ c).method(/*nonNullable*/ c);
}

void functionGetterCall_nullShorting(C? c) {
  c?.functionGetter(/*nonNullable*/ c).functionGetter(/*nonNullable*/ c);
}

void null_aware_cascades_promote_target(C? c) {
  c?..method(/*nonNullable*/ c);
  c?..functionGetter(/*nonNullable*/ c);
}

void null_aware_cascades_do_not_promote_others(C? c, int? i) {
  // Promotions that happen inside null-aware cascade sections
  // disappear after the cascade section, because they are not
  // guaranteed to execute.
  c?..method(i!);
  c?..functionGetter(i!);
  i;
}

void normal_cascades_do_promote_others(C c, int? i, int? j) {
  // Promotions that happen inside non-null-aware cascade sections
  // don't disappear after the cascade section.
  c..method(i!);
  c..functionGetter(j!);
  /*nonNullable*/ i;
  /*nonNullable*/ j;
}
