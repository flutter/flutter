// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

struct Bar : public Foo {
  int another_dummy;
};

// Ensure that scoped_refptr<A> -> scoped_refptr<B> conversions are not
// converted.
void ExpectsScopedPtr(const scoped_refptr<Foo>& foo) {
  scoped_refptr<Foo> temp(foo);
}

void CallExpectsScopedPtrWithBar() {
  scoped_refptr<Bar> temp(new Bar);
  ExpectsScopedPtr(temp);
}
