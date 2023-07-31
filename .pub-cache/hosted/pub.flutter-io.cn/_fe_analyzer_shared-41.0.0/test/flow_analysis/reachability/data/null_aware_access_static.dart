// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static void staticMethod(dynamic d) {}
  /*member: C.staticGetter:doesNotComplete*/
  static int get staticGetter => 0;
  /*member: C.staticInvokableGetter:doesNotComplete*/
  static void Function(dynamic d) get staticInvokableGetter => (_) {};
  static void set staticSetter(int value) {}
}

/*member: method_invocation_unreachable:doesNotComplete*/
void method_invocation_unreachable() {
  C?.staticMethod(throw '');
  /*stmt: unreachable*/ 0;
}

/*member: property_get_unreachable:doesNotComplete*/
void property_get_unreachable() {
  C?.staticGetter.remainder(throw '');
  /*stmt: unreachable*/ 0;
}

/*member: property_get_invocation_unreachable:doesNotComplete*/
void property_get_invocation_unreachable() {
  // We need a special test case for this because it parses like a method
  // invocation but the analyzer rewrites it as a property access followed by a
  // function expression invocation.
  C?.staticInvokableGetter(throw '');
  /*stmt: unreachable*/ 0;
}

/*member: property_set_unreachable:doesNotComplete*/
void property_set_unreachable() {
  C?.staticSetter = throw '';
  /*stmt: unreachable*/ 0;
}
