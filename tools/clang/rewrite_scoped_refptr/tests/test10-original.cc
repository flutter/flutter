// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

int TestsAScopedRefptr() {
  scoped_refptr<Foo> foo(new Foo);
  if (foo)
    return 1;
  return 0;
}
