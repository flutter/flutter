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
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "Hello");
}

TEST(CommentsTest, Nothing) {
  std::string test = R"test(
hello world
)test";

  std::vector<std::string> comments;
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 0u);
}

TEST(CommentsTest, Multiline) {
  std::string test = R"test(
/*
hello world
*/
dfdd
)test";

  std::vector<std::string> comments;
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "hello world\n");
}

TEST(CommentsTest, MultilineCpp) {
  std::string test = R"test(
doo
// hello
// world
daa
)test";

  std::vector<std::string> comments;
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "hello\nworld");
}

TEST(CommentsTest, CWithLeadingStars) {
  std::string test = R"test(
/*************
 * hello
 * world
 */
)test";

  std::vector<std::string> comments;
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "hello\nworld\n");
}

TEST(CommentsTest, CTextOnEndingLine) {
  std::string test = R"test(
/*hello
world*/
)test";

  std::vector<std::string> comments;
  IterateComments(test.c_str(), test.size(), [&](std::string_view comment) {
    comments.push_back(std::string(comment));
  });

  ASSERT_EQ(comments.size(), 1u);
  EXPECT_EQ(comments[0], "hello\nworld");
}
