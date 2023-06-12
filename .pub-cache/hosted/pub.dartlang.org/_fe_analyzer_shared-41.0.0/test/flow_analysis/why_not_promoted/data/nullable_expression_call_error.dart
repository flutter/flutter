// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableExpressionCallError`, for which we wish to report "why not
// promoted" context information.

class C1 {
  C2? bad;
}

class C2 {
  void call() {}
}

instance_method_invocation(C1 c) {
  if (c.bad == null) return;
  /*analyzer.notPromoted(propertyNotPromoted(target: member:C1.bad, type: C2?))*/ c
      .bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C1.bad, type: C2?))*/
      ();
}

class C3 {
  C4? ok;
  C5? bad;
}

class C4 {}

class C5 {}

extension on C4? {
  void call() {}
}

extension on C5 {
  void call() {}
}

extension_invocation_method(C3 c) {
  if (c.ok == null) return;
  c.ok();
  if (c.bad == null) return;
  /*analyzer.notPromoted(propertyNotPromoted(target: member:C3.bad, type: C5?))*/ c
      .bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C3.bad, type: C5?))*/
      ();
}

class C6 {
  C7? bad;
}

class C7 {
  void Function() get call => () {};
}

instance_getter_invocation(C6 c) {
  if (c.bad == null) return;
  /*analyzer.notPromoted(propertyNotPromoted(target: member:C6.bad, type: C7?))*/ c
      .bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C6.bad, type: C7?))*/
      ();
}

class C8 {
  C9? ok;
  C10? bad;
}

class C9 {}

class C10 {}

extension on C9? {
  void Function() get call => () {};
}

extension on C10 {
  void Function() get call => () {};
}

extension_invocation_getter(C8 c) {
  if (c.ok == null) return;
  c.ok();
  if (c.bad == null) return;
  /*analyzer.notPromoted(propertyNotPromoted(target: member:C8.bad, type: C10?))*/ c
      .bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C8.bad, type: C10?))*/
      ();
}

class C11 {
  void Function()? bad;
}

function_invocation(C11 c) {
  if (c.bad == null) return;
  /*analyzer.notPromoted(propertyNotPromoted(target: member:C11.bad, type: void Function()?))*/ c
      .bad
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C11.bad, type: void Function()?))*/
      ();
}

class C12 {
  C13? bad;
}

class C13 {
  void Function() foo;
  C13(this.foo);
}

instance_field_invocation(C12 c) {
  if (c.bad == null) return;
  c.bad
      .
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C12.bad, type: C13?))*/
      foo
      /*cfe.invoke: notPromoted(propertyNotPromoted(target: member:C12.bad, type: C13?))*/
      ();
}
