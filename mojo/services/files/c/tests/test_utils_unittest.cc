// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/tests/test_utils.h"

#include <errno.h>

#include "files/c/tests/mock_errno_impl.h"
#include "files/c/tests/mojio_impl_test_base.h"
#include "files/c/tests/test_utils.h"

using mojo::SynchronousInterfacePtr;

namespace mojio {
namespace test {
namespace {

using TestUtilsTest = mojio::test::MojioImplTestBase;

TEST_F(TestUtilsTest, MakeDirAt) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  EXPECT_EQ(-1, GetFileSize(&dir, "my_file"));
  EXPECT_EQ(-1, GetFileSize(&dir, "my_dir/my_file"));

  MakeDirAt(&dir, "my_dir");

  EXPECT_EQ(-1, GetFileSize(&dir, "my_file"));
  EXPECT_EQ(-1, GetFileSize(&dir, "my_dir/my_file"));

  CreateTestFileAt(&dir, "my_dir/my_file", 123);

  EXPECT_EQ(-1, GetFileSize(&dir, "my_file"));
  EXPECT_EQ(123, GetFileSize(&dir, "my_dir/my_file"));
}

TEST_F(TestUtilsTest, OpenFileAt) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  EXPECT_FALSE(OpenFileAt(&dir, "nonexistent", mojo::files::kOpenFlagWrite));
  EXPECT_TRUE(OpenFileAt(&dir, "created", mojo::files::kOpenFlagWrite |
                                              mojo::files::kOpenFlagCreate));
  EXPECT_TRUE(OpenFileAt(&dir, "created", mojo::files::kOpenFlagRead));
}

TEST_F(TestUtilsTest, CreateTestFileAtGetFileSizeGetFileContents) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  CreateTestFileAt(&dir, "file_0", 0);
  CreateTestFileAt(&dir, "file_123", 123);
  CreateTestFileAt(&dir, "file_456", 456);

  EXPECT_EQ(0, GetFileSize(&dir, "file_0"));
  EXPECT_EQ(123, GetFileSize(&dir, "file_123"));
  EXPECT_EQ(456, GetFileSize(&dir, "file_456"));
  EXPECT_EQ(-1, GetFileSize(&dir, "nonexistent"));

  EXPECT_EQ(std::string(), GetFileContents(&dir, "file_0"));

  std::string s_123(123, '\0');
  for (size_t i = 0; i < 123; i++) {
    unsigned char c = static_cast<unsigned char>(i);
    s_123[i] = *reinterpret_cast<char*>(&c);
  }
  EXPECT_EQ(s_123, GetFileContents(&dir, "file_123"));

  std::string s_456(456, '\0');
  for (size_t i = 0; i < 456; i++) {
    unsigned char c = static_cast<unsigned char>(i);
    s_456[i] = *reinterpret_cast<char*>(&c);
  }
  EXPECT_EQ(s_456, GetFileContents(&dir, "file_456"));
}

}  // namespace
}  // namespace test
}  // namespace mojio
