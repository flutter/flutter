// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/array_string/array_string_type_converters.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace test {
namespace {

TEST(CommonTypeConvertersTest, ArrayUint8ToStdString) {
  Array<uint8_t> data(4);
  data[0] = 'd';
  data[1] = 'a';
  data[2] = 't';
  data[3] = 'a';

  EXPECT_EQ("data", data.To<std::string>());
}

TEST(CommonTypeConvertersTest, StdStringToArrayUint8) {
  std::string input("data");
  Array<uint8_t> data = Array<uint8_t>::From(input);

  ASSERT_EQ(4ul, data.size());
  EXPECT_EQ('d', data[0]);
  EXPECT_EQ('a', data[1]);
  EXPECT_EQ('t', data[2]);
  EXPECT_EQ('a', data[3]);
}

}  // namespace
}  // namespace test
}  // namespace common
}  // namespace mojo
