// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/ref_counted.h"
#include "testing/gtest/include/gtest/gtest.h"

struct Foo : public base::RefCounted<Foo> {
  int dummy;
};

void TestFunction() {
  scoped_refptr<Foo> a;
  Foo* b;

  ASSERT_EQ(a, b);
  ASSERT_EQ(b, a);
  EXPECT_EQ(a, b);
  EXPECT_EQ(b, a);

  ASSERT_NE(a, b);
  ASSERT_NE(b, a);
  EXPECT_NE(a, b);
  EXPECT_NE(b, a);

  ASSERT_TRUE(a);
  ASSERT_FALSE(!a);
  EXPECT_TRUE(a);
  EXPECT_FALSE(!a);
}
