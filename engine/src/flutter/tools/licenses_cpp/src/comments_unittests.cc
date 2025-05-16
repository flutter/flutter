// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/comments.h"
#include "gtest/gtest.h"

#include <sstream>

TEST(CommentsTest, Simple) {
  std::string test = R"test(
// Hello
)test";

  std::vector<std::string> comments;
  lex(test.c_str(), test.size(), [&](const char* comment) {
    comments.push_back(comment);
  });

  EXPECT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "// Hello");
}
