// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

// Case 2: An example of an unsafe conversion, where the scoped_refptr<> is
// returned as a temporary, and as such both it and its object are only valid
// for the duration of the full expression.
scoped_refptr<Foo> GetBuggyFoo() {
  return new Foo;
}
void UseBuggyFoo() {
  scoped_refptr<Foo> unsafe = GetBuggyFoo();
}
