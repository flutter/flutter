// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

typedef std::vector<scoped_refptr<Foo> > FooList;

void TestsAScopedRefptr() {
  FooList list;
  list.push_back(new Foo);
  list.push_back(new Foo);
  for (FooList::const_iterator it = list.begin(); it != list.end(); ++it) {
    if (!*it)
      continue;
    Foo* item = *it;
  }
}
