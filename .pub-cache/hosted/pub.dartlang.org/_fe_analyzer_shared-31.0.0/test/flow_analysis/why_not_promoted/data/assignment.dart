// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class C {
  C? operator +(int i);
  int get cProperty => 0;
}

direct_assignment(int? i, int? j) {
  if (i == null) return;
  /*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i = j;
  i. /*notPromoted(explicitWrite)*/ isEven;
}

compound_assignment(C? c, int i) {
  if (c == null) return;
  /*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ c += i;
  c. /*notPromoted(explicitWrite)*/ cProperty;
}

via_postfix_op(C? c) {
  if (c == null) return;
  /*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ c++;
  c. /*notPromoted(explicitWrite)*/ cProperty;
}

via_prefix_op(C? c) {
  if (c == null) return;
  /*analyzer.explicitWrite*/ ++ /*cfe.update: explicitWrite*/ c;
  c. /*notPromoted(explicitWrite)*/ cProperty;
}

via_for_each_statement(int? i, List<int?> list) {
  if (i == null) return;
  for (/*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i in list) {
    i. /*notPromoted(explicitWrite)*/ isEven;
  }
}

via_for_each_list_element(int? i, List<int?> list) {
  if (i == null) return;
  [
    for (/*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i in list)
      i. /*notPromoted(explicitWrite)*/ isEven
  ];
}

via_for_each_set_element(int? i, List<int?> list) {
  if (i == null) return;
  ({
    for (/*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i in list)
      i. /*notPromoted(explicitWrite)*/ isEven
  });
}

via_for_each_map_key(int? i, List<int?> list) {
  if (i == null) return;
  ({
    for (/*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i in list)
      i. /*notPromoted(explicitWrite)*/ isEven: null
  });
}

via_for_each_map_value(int? i, List<int?> list) {
  if (i == null) return;
  ({
    for (/*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i in list)
      null: i. /*notPromoted(explicitWrite)*/ isEven
  });
}
