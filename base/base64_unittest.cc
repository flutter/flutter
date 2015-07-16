// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/base64.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(Base64Test, Basic) {
  const std::string kText = "hello world";
  const std::string kBase64Text = "aGVsbG8gd29ybGQ=";

  std::string encoded;
  std::string decoded;
  bool ok;

  Base64Encode(kText, &encoded);
  EXPECT_EQ(kBase64Text, encoded);

  ok = Base64Decode(encoded, &decoded);
  EXPECT_TRUE(ok);
  EXPECT_EQ(kText, decoded);
}

TEST(Base64Test, InPlace) {
  const std::string kText = "hello world";
  const std::string kBase64Text = "aGVsbG8gd29ybGQ=";
  std::string text(kText);

  Base64Encode(text, &text);
  EXPECT_EQ(kBase64Text, text);

  bool ok = Base64Decode(text, &text);
  EXPECT_TRUE(ok);
  EXPECT_EQ(text, kText);
}

}  // namespace base
