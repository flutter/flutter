// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

struct Foo {
  int dummy;
};

void ExpectsScopedRefptr(const scoped_refptr<Foo>& param) {
  Foo* foo = param;
}

void CallExpectsScopedRefptr() {
  scoped_refptr<Foo> temp(new Foo);
  ExpectsScopedRefptr(temp);
}

void CallExpectsScopedRefptrWithRawPtr() {
  ExpectsScopedRefptr(new Foo);
}
