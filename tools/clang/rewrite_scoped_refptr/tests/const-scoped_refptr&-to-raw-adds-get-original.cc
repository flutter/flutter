// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "scoped_refptr.h"

class Foo {
  int dummy;
};

class Bar {
 public:
  const scoped_refptr<Foo>& foo() const { return foo_; }

 private:
  scoped_refptr<Foo> foo_;
};

void TestFunction() {
  Bar b;
  Foo* f = b.foo();
}
