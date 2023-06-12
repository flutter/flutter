// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  void set setter(value) {}
  C operator [](index) => this;
  void operator []=(index, value) {}
  C get getterReturningC => this;
  C? get getterReturningNullableC => this;
  C get getterSetter => this;
  void set getterSetter(value) {}
  C operator +(other) => this;
}

class D {
  void set setter(value) {}
  C? operator [](index) => C();
  void operator []=(index, value) {}
  D get getterSetter => this;
  void set getterSetter(value) {}
  D operator +(other) => this;
}

void setterCall(C? c) {
  c?.setter = /*nonNullable*/ c;
}

void compoundAssign(C? c) {
  c?.getterSetter += /*nonNullable*/ c;
}

void nullAwareAssign(C? c) {
  c?.getterSetter ??= /*nonNullable*/ c;
}

void indexGetterCall(C? c) {
  c?[/*nonNullable*/ c];
}

void indexSetterCall(C? c) {
  c?[/*nonNullable*/ c] = /*nonNullable*/ c;
}

void indexCompoundAssign(C? c) {
  c?[/*nonNullable*/ c] += /*nonNullable*/ c;
}

void indexNullAwareAssign(C? c) {
  c?[/*nonNullable*/ c] ??= /*nonNullable*/ c;
}

void setterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC.setter = /*nonNullable*/ c;
  c?.getterReturningNullableC?.setter = /*nonNullable*/ c;
  c?[0].setter = /*nonNullable*/ c;
  d?[0]?.setter = /*nonNullable*/ d;
}

void compoundAssign_nullShorting(C? c, D? d) {
  c?.getterReturningC.getterSetter += /*nonNullable*/ c;
  c?.getterReturningNullableC?.getterSetter += /*nonNullable*/ c;
  c?[0].getterSetter += /*nonNullable*/ c;
  d?[0]?.getterSetter += /*nonNullable*/ d;
}

void nullAwareAssign_nullShorting(C? c, D? d) {
  c?.getterReturningC.getterSetter ??= /*nonNullable*/ c;
  c?.getterReturningNullableC?.getterSetter ??= /*nonNullable*/ c;
  c?[0].getterSetter ??= /*nonNullable*/ c;
  d?[0]?.getterSetter ??= /*nonNullable*/ d;
}

void indexGetterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c];
  c?.getterReturningNullableC?[/*nonNullable*/ c];
  c?[0][/*nonNullable*/ c];
  d?[0]?[/*nonNullable*/ d];
}

void indexSetterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c] = /*nonNullable*/ c;
  c?.getterReturningNullableC?[/*nonNullable*/ c] = /*nonNullable*/ c;
  c?[0][/*nonNullable*/ c] = /*nonNullable*/ c;
  d?[0]?[/*nonNullable*/ d] = /*nonNullable*/ d;
}

void indexCompoundAssign_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c] += /*nonNullable*/ c;
  c?.getterReturningNullableC?[/*nonNullable*/ c] += /*nonNullable*/ c;
  c?[0][/*nonNullable*/ c] += /*nonNullable*/ c;
  d?[0]?[/*nonNullable*/ d] += /*nonNullable*/ d;
}

void indexNullAwareAssign_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c] ??= /*nonNullable*/ c;
  c?.getterReturningNullableC?[/*nonNullable*/ c] ??= /*nonNullable*/ c;
  c?[0][/*nonNullable*/ c] ??= /*nonNullable*/ c;
  d?[0]?[/*nonNullable*/ d] ??= /*nonNullable*/ d;
}

void null_aware_cascades_do_not_promote_target(C? c) {
  // Cascaded invocations act on an invisible temporary variable that
  // holds the result of evaluating the cascade target.  So
  // effectively, no promotion happens (because there is no way to
  // observe a change to the type of that variable).
  c?..setter = /*nonNullable*/ c;
  c?..getterSetter += /*nonNullable*/ c;
  c?..getterSetter ??= /*nonNullable*/ c;
  c?..[/*nonNullable*/ c];
  c?..[/*nonNullable*/ c] = /*nonNullable*/ c;
  c?..[/*nonNullable*/ c] += /*nonNullable*/ c;
  c?..[/*nonNullable*/ c] ??= /*nonNullable*/ c;
}

void null_aware_cascades_do_not_promote_others(C? c, int? i, int? j) {
  // Promotions that happen inside null-aware cascade sections
  // disappear after the cascade section, because they are not
  // guaranteed to execute.
  c?..setter = i!;
  c?..getterSetter += i!;
  c?..getterSetter ??= i!;
  c?..[i!];
  c?..[i!] = j!;
  c?..[i!] += j!;
  c?..[i!] ??= j!;
  i;
  j;
}

void normal_cascades_do_promote_others(C c, int? i, int? j, int? k, int? l,
    int? m, int? n, int? o, int? p, int? q, int? r) {
  // Promotions that happen inside non-null-aware cascade sections
  // don't disappear after the cascade section.
  c..setter = i!;
  c..getterSetter += m!;
  c..getterSetter ??= n!;
  c..[j!];
  c..[k!] = l!;
  c..[o!] += p!;
  c..[q!] ??= r!;
  /*nonNullable*/ i;
  /*nonNullable*/ j;
  /*nonNullable*/ k;
  /*nonNullable*/ l;
  /*nonNullable*/ m;
  n; // Not promoted because `n!` is on the RHS of `??=`
  /*nonNullable*/ o;
  /*nonNullable*/ p;
}
