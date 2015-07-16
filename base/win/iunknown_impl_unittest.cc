// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/iunknown_impl.h"

#include "base/win/scoped_com_initializer.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

class TestIUnknownImplSubclass : public IUnknownImpl {
 public:
  TestIUnknownImplSubclass() {
    ++instance_count;
  }
  ~TestIUnknownImplSubclass() override { --instance_count; }
  static int instance_count;
};

// static
int TestIUnknownImplSubclass::instance_count = 0;

TEST(IUnknownImplTest, IUnknownImpl) {
  ScopedCOMInitializer com_initializer;

  EXPECT_EQ(0, TestIUnknownImplSubclass::instance_count);
  IUnknown* u = new TestIUnknownImplSubclass();

  EXPECT_EQ(1, TestIUnknownImplSubclass::instance_count);

  EXPECT_EQ(1, u->AddRef());
  EXPECT_EQ(1, u->AddRef());

  IUnknown* other = NULL;
  EXPECT_EQ(E_NOINTERFACE, u->QueryInterface(
      IID_IDispatch, reinterpret_cast<void**>(&other)));
  EXPECT_EQ(S_OK, u->QueryInterface(
      IID_IUnknown, reinterpret_cast<void**>(&other)));
  other->Release();

  EXPECT_EQ(1, u->Release());
  EXPECT_EQ(0, u->Release());
  EXPECT_EQ(0, TestIUnknownImplSubclass::instance_count);
}

}  // namespace win
}  // namespace base
