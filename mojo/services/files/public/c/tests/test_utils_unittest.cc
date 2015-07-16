// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/tests/test_utils.h"

#include <errno.h>

#include "files/public/c/tests/mock_errno_impl.h"
#include "files/public/c/tests/mojio_impl_test_base.h"
#include "files/public/c/tests/test_utils.h"

namespace mojio {
namespace test {
namespace {

using TestUtilsTest = mojio::test::MojioImplTestBase;

TEST_F(TestUtilsTest, MakeDirAt) {
  EXPECT_EQ(-1, GetFileSize(&directory(), "my_file"));
  EXPECT_EQ(-1, GetFileSize(&directory(), "my_dir/my_file"));

  MakeDirAt(&directory(), "my_dir");

  EXPECT_EQ(-1, GetFileSize(&directory(), "my_file"));
  EXPECT_EQ(-1, GetFileSize(&directory(), "my_dir/my_file"));

  CreateTestFileAt(&directory(), "my_dir/my_file", 123);

  EXPECT_EQ(-1, GetFileSize(&directory(), "my_file"));
  EXPECT_EQ(123, GetFileSize(&directory(), "my_dir/my_file"));
}

TEST_F(TestUtilsTest, OpenFileAt) {
  EXPECT_FALSE(
      OpenFileAt(&directory(), "nonexistent", mojo::files::kOpenFlagWrite));
  EXPECT_TRUE(
      OpenFileAt(&directory(), "created",
                 mojo::files::kOpenFlagWrite | mojo::files::kOpenFlagCreate));
  EXPECT_TRUE(OpenFileAt(&directory(), "created", mojo::files::kOpenFlagRead));
}

TEST_F(TestUtilsTest, CreateTestFileAtGetFileSizeGetFileContents) {
  CreateTestFileAt(&directory(), "file_0", 0);
  CreateTestFileAt(&directory(), "file_123", 123);
  CreateTestFileAt(&directory(), "file_456", 456);

  EXPECT_EQ(0, GetFileSize(&directory(), "file_0"));
  EXPECT_EQ(123, GetFileSize(&directory(), "file_123"));
  EXPECT_EQ(456, GetFileSize(&directory(), "file_456"));
  EXPECT_EQ(-1, GetFileSize(&directory(), "nonexistent"));

  EXPECT_EQ(std::string(), GetFileContents(&directory(), "file_0"));

  std::string s_123(123, '\0');
  for (size_t i = 0; i < 123; i++) {
    unsigned char c = static_cast<unsigned char>(i);
    s_123[i] = *reinterpret_cast<char*>(&c);
  }
  EXPECT_EQ(s_123, GetFileContents(&directory(), "file_123"));

  std::string s_456(456, '\0');
  for (size_t i = 0; i < 456; i++) {
    unsigned char c = static_cast<unsigned char>(i);
    s_456[i] = *reinterpret_cast<char*>(&c);
  }
  EXPECT_EQ(s_456, GetFileContents(&directory(), "file_456"));
}

}  // namespace
}  // namespace test
}  // namespace mojio
