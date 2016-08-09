// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

// A temporary scoped_refptr<T> is used in a boolean test. This doesn't result
// in memory safety issues, but probably indicates a code smell. As such, the
// tool intentionally skips this case so it can be manually handled.
scoped_refptr<Foo> GetBuggyFoo() {
  return new Foo;
}
void UseBuggyFoo() {
  if (GetBuggyFoo())
    return;
}
