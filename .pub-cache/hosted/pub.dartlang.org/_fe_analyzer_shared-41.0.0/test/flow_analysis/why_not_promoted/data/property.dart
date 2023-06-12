// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? get i => null;
  int? get j => null;

  get_property_via_explicit_this() {
    if (this.i == null) return;
    this
        .i
        . /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
  }

  get_property_via_explicit_this_parenthesized() {
    if ((this).i == null) return;
    (this)
        .i
        . /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
  }

  get_property_by_implicit_this() {
    if (i == null) return;
    i. /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
  }
}

class D extends C {
  get_property_via_explicit_super() {
    if (super.i == null) return;
    super
        .i
        . /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
  }

  get_property_by_implicit_super() {
    if (i == null) return;
    i. /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
  }
}

get_property_via_prefixed_identifier(C c) {
  if (c.i == null) return;
  c.i. /*notPromoted(propertyNotPromoted(target: member:C.i, type: int?))*/ isEven;
}

get_property_via_prefixed_identifier_mismatched_target(C c1, C c2) {
  // Note: no context on this error because the property the user is attempting
  // to promote is on c1, but the property the user is accessing is on c2.
  if (c1.i == null) return;
  c2.i.isEven;
}

get_property_via_prefixed_identifier_mismatched_property(C c) {
  // Note: no context on this error because the property the user is attempting
  // to promote is C.i, but the property the user is accessing is C.j.
  if (c.i == null) return;
  c.j.isEven;
}
