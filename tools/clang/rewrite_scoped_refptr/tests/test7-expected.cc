// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

void ExpectsRawPtr(Foo* foo) {
  Foo* temp = foo;
}

// Ensure that de-referencing scoped_refptr<>'s are properly rewritten as
// ->get() calls.
Foo* GetHeapFoo() {
  scoped_refptr<Foo>* heap_allocated = new scoped_refptr<Foo>();
  *heap_allocated = new Foo;
  return heap_allocated->get();
}
