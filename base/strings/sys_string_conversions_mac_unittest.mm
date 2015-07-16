// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#include "base/strings/string16.h"
#include "base/strings/sys_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(SysStrings, ConversionsFromNSString) {
  EXPECT_STREQ("Hello, world!", SysNSStringToUTF8(@"Hello, world!").c_str());

  // Conversions should be able to handle a NULL value without crashing.
  EXPECT_STREQ("", SysNSStringToUTF8(nil).c_str());
  EXPECT_EQ(string16(), SysNSStringToUTF16(nil));
}

}  // namespace base
