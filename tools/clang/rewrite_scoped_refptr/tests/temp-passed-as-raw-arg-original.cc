// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

// A temporary scoped_refptr is passed as a raw pointer function argument. Since
// temporaries are destroyed at the end of the full expression, this is 'safe'
// and could be rewritten to use get(). However, the tool just skips this case
// This should be rare enough that manual intervention is sufficient, since
// seeing this pattern probably indicates a code smell.
scoped_refptr<Foo> GetBuggyFoo() {
  return new Foo;
}

void Bar(Foo* f);

void UseBuggyFoo() {
  Bar(GetBuggyFoo());
}
