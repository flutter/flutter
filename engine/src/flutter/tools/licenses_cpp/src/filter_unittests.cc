// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/filter.h"
#include "gtest/gtest.h"

#include <sstream>

TEST(FilterTest, Simple) {
  std::stringstream ss;
  ss << ".*\\.dart" << std::endl;
  ss << ".*\\.cc" << std::endl;

  absl::StatusOr<Filter> filter = Filter::Open(ss);
  ASSERT_TRUE(filter.ok());
  EXPECT_TRUE(filter->Matches("foo/bar/baz.dart"));
  EXPECT_TRUE(filter->Matches("foo/bar/baz.cc"));
  EXPECT_FALSE(filter->Matches("foo/bar/baz.txt"));
}

TEST(FilterTest, Comments) {
  std::stringstream ss;
  ss << ".*\\.dart" << std::endl;
  ss << "# hello!" << std::endl;
  ss << ".*\\.cc" << std::endl;

  absl::StatusOr<Filter> filter = Filter::Open(ss);
  ASSERT_TRUE(filter.ok());
  EXPECT_TRUE(filter->Matches("foo/bar/baz.dart"));
  EXPECT_TRUE(filter->Matches("foo/bar/baz.cc"));
  EXPECT_FALSE(filter->Matches("foo/bar/baz.txt"));
}
