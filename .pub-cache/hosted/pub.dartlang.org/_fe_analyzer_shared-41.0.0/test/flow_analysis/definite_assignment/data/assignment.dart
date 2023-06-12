// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

leftExpression() {
  late List<int> v;
  /*unassigned*/ v[0] = (v = [1, 2])[1];
  v;
}

leftLocal_compound() {
  late int v;
  /*unassigned*/ v += 1;
}

leftLocal_compound_assignInRight() {
  late int v;
  /*unassigned*/ v += (v = /*unassigned*/ v);
}

leftLocal_pure_eq() {
  late int v;
  v = 0;
}

leftLocal_pure_eq_self() {
  late int v;
  v = /*unassigned*/ v;
}

leftLocal_pure_questionEq() {
  late int v;
  /*unassigned*/ v ??= 0;
}

leftLocal_pure_questionEq_self() {
  late int v;
  /*unassigned*/ v ??= /*unassigned*/ v;
}

questionEq_rhs_not_guaranteed_to_execute() {
  late int v;
  int? i;
  /*unassigned*/ i ??= (v = 0);
  /*unassigned*/ v;
}
