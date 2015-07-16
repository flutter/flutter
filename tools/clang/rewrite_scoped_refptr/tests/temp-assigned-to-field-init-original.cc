// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

// Similar to case 2, but with a field initializer.
scoped_refptr<Foo> GetBuggyFoo() {
  return new Foo;
}

class ABuggyCtor {
  ABuggyCtor() : f_(GetBuggyFoo()) {}
  Foo* f_;
};
