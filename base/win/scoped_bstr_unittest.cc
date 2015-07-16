// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_bstr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

namespace {

static const wchar_t kTestString1[] = L"123";
static const wchar_t kTestString2[] = L"456789";
size_t test1_len = arraysize(kTestString1) - 1;
size_t test2_len = arraysize(kTestString2) - 1;

void DumbBstrTests() {
  ScopedBstr b;
  EXPECT_TRUE(b == NULL);
  EXPECT_EQ(0, b.Length());
  EXPECT_EQ(0, b.ByteLength());
  b.Reset(NULL);
  EXPECT_TRUE(b == NULL);
  EXPECT_TRUE(b.Release() == NULL);
  ScopedBstr b2;
  b.Swap(b2);
  EXPECT_TRUE(b2 == NULL);
}

void GiveMeABstr(BSTR* ret) {
  *ret = SysAllocString(kTestString1);
}

void BasicBstrTests() {
  ScopedBstr b1(kTestString1);
  EXPECT_EQ(test1_len, b1.Length());
  EXPECT_EQ(test1_len * sizeof(kTestString1[0]), b1.ByteLength());

  ScopedBstr b2;
  b1.Swap(b2);
  EXPECT_EQ(test1_len, b2.Length());
  EXPECT_EQ(0, b1.Length());
  EXPECT_EQ(0, lstrcmp(b2, kTestString1));
  BSTR tmp = b2.Release();
  EXPECT_TRUE(tmp != NULL);
  EXPECT_EQ(0, lstrcmp(tmp, kTestString1));
  EXPECT_TRUE(b2 == NULL);
  SysFreeString(tmp);

  GiveMeABstr(b2.Receive());
  EXPECT_TRUE(b2 != NULL);
  b2.Reset();
  EXPECT_TRUE(b2.AllocateBytes(100) != NULL);
  EXPECT_EQ(100, b2.ByteLength());
  EXPECT_EQ(100 / sizeof(kTestString1[0]), b2.Length());
  lstrcpy(static_cast<BSTR>(b2), kTestString1);
  EXPECT_EQ(test1_len, lstrlen(b2));
  EXPECT_EQ(100 / sizeof(kTestString1[0]), b2.Length());
  b2.SetByteLen(lstrlen(b2) * sizeof(kTestString2[0]));
  EXPECT_EQ(b2.Length(), lstrlen(b2));

  EXPECT_TRUE(b1.Allocate(kTestString2) != NULL);
  EXPECT_EQ(test2_len, b1.Length());
  b1.SetByteLen((test2_len - 1) * sizeof(kTestString2[0]));
  EXPECT_EQ(test2_len - 1, b1.Length());
}

}  // namespace

TEST(ScopedBstrTest, ScopedBstr) {
  DumbBstrTests();
  BasicBstrTests();
}

}  // namespace win
}  // namespace base
