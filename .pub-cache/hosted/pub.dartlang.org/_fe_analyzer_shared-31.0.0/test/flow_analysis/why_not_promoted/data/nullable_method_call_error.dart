// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableMethodCallError`, for which we wish to report "why not
// promoted" context information.

class C {
  int? i;
  void Function()? f;
}

extension on int {
  get propertyOnNonNullInt => null;
  void methodOnNonNullInt() {}
}

extension on int? {
  get propertyOnNullableInt => null;
  void methodOnNullableInt() {}
}

property_get_of_variable(int? i, int? j) {
  if (i == null) return;
  /*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i = j;
  i. /*notPromoted(explicitWrite)*/ isEven;
}

extension_property_get_of_variable(int? i, int? j) {
  if (i == null) return;
  /*cfe.update: explicitWrite*/ /*analyzer.explicitWrite*/ i = j;
  i.propertyOnNullableInt;
  i.
      /*cfe.invoke: notPromoted(explicitWrite)*/
      /*analyzer.notPromoted(explicitWrite)*/
      propertyOnNonNullInt;
}

property_get_of_expression(C c) {
  if (c.i == null) return;
  c.i. /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
}

extension_property_get_of_expression(C c) {
  if (c.i == null) return;
  c.i.propertyOnNullableInt;
  c
      .i
      .
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      propertyOnNonNullInt;
}

method_invocation(C c) {
  if (c.i == null) return;
  c.i
      .
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      abs();
}

extension_method_invocation(C c) {
  if (c.i == null) return;
  c.i.methodOnNullableInt();
  c.i
      .
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/
      methodOnNonNullInt();
}

call_invocation(C c) {
  if (c.f == null) return;
  c.f
      .
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C.f, type: void Function()?))*/
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C.f, type: void Function()?))*/
      call();
}
