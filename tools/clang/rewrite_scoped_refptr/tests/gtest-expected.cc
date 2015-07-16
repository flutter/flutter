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

  ASSERT_EQ(a.get(), b);
  ASSERT_EQ(b, a.get());
  EXPECT_EQ(a.get(), b);
  EXPECT_EQ(b, a.get());

  ASSERT_NE(a.get(), b);
  ASSERT_NE(b, a.get());
  EXPECT_NE(a.get(), b);
  EXPECT_NE(b, a.get());

  ASSERT_TRUE(a.get());
  ASSERT_FALSE(!a.get());
  EXPECT_TRUE(a.get());
  EXPECT_FALSE(!a.get());
}
