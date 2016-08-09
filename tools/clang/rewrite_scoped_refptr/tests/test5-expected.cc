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

// Ensure that the correct cast (the user-defined cast) is converted.
void ExpectsRawFooPtr(Foo* foo) {
  Foo* temp = foo;
}

void CallExpectsRawFooPtrWithBar() {
  scoped_refptr<Bar> temp(new Bar);
  ExpectsRawFooPtr(temp.get());
}
