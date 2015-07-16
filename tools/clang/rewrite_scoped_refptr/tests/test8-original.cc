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

void ExpectsRawPtr(Foo* foo) {
  Foo* temp = foo;
}

// Ensure that de-referencing scoped_refptr<>'s are properly rewritten as
// ->get() calls, and that the correct conversion is rewritten (eg: not the
// Bar* -> Foo* conversion).
Foo* GetHeapFoo() {
  scoped_refptr<Bar>* heap_allocated = new scoped_refptr<Bar>();
  *heap_allocated = new Bar;
  return *heap_allocated;
}
