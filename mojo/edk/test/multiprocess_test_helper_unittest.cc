// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/multiprocess_test_helper.h"

#include "base/logging.h"
#include "build/build_config.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/test/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_POSIX)
#include <fcntl.h>
#endif

namespace mojo {
namespace test {
namespace {

bool IsNonBlocking(const embedder::PlatformHandle& handle) {
#if defined(OS_WIN)
  // Haven't figured out a way to query whether a HANDLE was created with
  // FILE_FLAG_OVERLAPPED.
  return true;
#else
  return fcntl(handle.fd, F_GETFL) & O_NONBLOCK;
#endif
}

bool WriteByte(const embedder::PlatformHandle& handle, char c) {
  size_t bytes_written = 0;
  BlockingWrite(handle, &c, 1, &bytes_written);
  return bytes_written == 1;
}

bool ReadByte(const embedder::PlatformHandle& handle, char* c) {
  size_t bytes_read = 0;
  BlockingRead(handle, c, 1, &bytes_read);
  return bytes_read == 1;
}

using MultiprocessTestHelperTest = testing::Test;

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_RunChild DISABLED_RunChild
#else
#define MAYBE_RunChild RunChild
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_RunChild) {
  MultiprocessTestHelper helper;
  EXPECT_TRUE(helper.server_platform_handle.is_valid());

  helper.StartChild("RunChild");
  EXPECT_EQ(123, helper.WaitForChildShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_MAIN(RunChild) {
  CHECK(MultiprocessTestHelper::client_platform_handle.is_valid());
  return 123;
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_TestChildMainNotFound DISABLED_TestChildMainNotFound
#else
#define MAYBE_TestChildMainNotFound TestChildMainNotFound
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_TestChildMainNotFound) {
  MultiprocessTestHelper helper;
  helper.StartChild("NoSuchTestChildMain");
  int result = helper.WaitForChildShutdown();
  EXPECT_FALSE(result >= 0 && result <= 127);
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_PassedChannel DISABLED_PassedChannel
#else
#define MAYBE_PassedChannel PassedChannel
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_PassedChannel) {
  MultiprocessTestHelper helper;
  EXPECT_TRUE(helper.server_platform_handle.is_valid());
  helper.StartChild("PassedChannel");

  // Take ownership of the handle.
  embedder::ScopedPlatformHandle handle = helper.server_platform_handle.Pass();

  // The handle should be non-blocking.
  EXPECT_TRUE(IsNonBlocking(handle.get()));

  // Write a byte.
  const char c = 'X';
  EXPECT_TRUE(WriteByte(handle.get(), c));

  // It'll echo it back to us, incremented.
  char d = 0;
  EXPECT_TRUE(ReadByte(handle.get(), &d));
  EXPECT_EQ(c + 1, d);

  // And return it, incremented again.
  EXPECT_EQ(c + 2, helper.WaitForChildShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_MAIN(PassedChannel) {
  CHECK(MultiprocessTestHelper::client_platform_handle.is_valid());

  // Take ownership of the handle.
  embedder::ScopedPlatformHandle handle =
      MultiprocessTestHelper::client_platform_handle.Pass();

  // The handle should be non-blocking.
  EXPECT_TRUE(IsNonBlocking(handle.get()));

  // Read a byte.
  char c = 0;
  EXPECT_TRUE(ReadByte(handle.get(), &c));

  // Write it back, incremented.
  c++;
  EXPECT_TRUE(WriteByte(handle.get(), c));

  // And return it, incremented again.
  c++;
  return static_cast<int>(c);
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_ChildTestPasses DISABLED_ChildTestPasses
#else
#define MAYBE_ChildTestPasses ChildTestPasses
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_ChildTestPasses) {
  MultiprocessTestHelper helper;
  EXPECT_TRUE(helper.server_platform_handle.is_valid());
  helper.StartChild("ChildTestPasses");
  EXPECT_TRUE(helper.WaitForChildTestShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_TEST(ChildTestPasses) {
  ASSERT_TRUE(MultiprocessTestHelper::client_platform_handle.is_valid());
  EXPECT_TRUE(
      IsNonBlocking(MultiprocessTestHelper::client_platform_handle.get()));
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_ChildTestFailsAssert DISABLED_ChildTestFailsAssert
#else
#define MAYBE_ChildTestFailsAssert ChildTestFailsAssert
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_ChildTestFailsAssert) {
  MultiprocessTestHelper helper;
  EXPECT_TRUE(helper.server_platform_handle.is_valid());
  helper.StartChild("ChildTestFailsAssert");
  EXPECT_FALSE(helper.WaitForChildTestShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_TEST(ChildTestFailsAssert) {
  ASSERT_FALSE(MultiprocessTestHelper::client_platform_handle.is_valid())
      << "DISREGARD: Expected failure in child process";
  ASSERT_FALSE(
      IsNonBlocking(MultiprocessTestHelper::client_platform_handle.get()))
      << "Not reached";
  CHECK(false) << "Not reached";
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_ChildTestFailsExpect DISABLED_ChildTestFailsExpect
#else
#define MAYBE_ChildTestFailsExpect ChildTestFailsExpect
#endif  // defined(OS_ANDROID)
TEST_F(MultiprocessTestHelperTest, MAYBE_ChildTestFailsExpect) {
  MultiprocessTestHelper helper;
  EXPECT_TRUE(helper.server_platform_handle.is_valid());
  helper.StartChild("ChildTestFailsExpect");
  EXPECT_FALSE(helper.WaitForChildTestShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_TEST(ChildTestFailsExpect) {
  EXPECT_FALSE(MultiprocessTestHelper::client_platform_handle.is_valid())
      << "DISREGARD: Expected failure #1 in child process";
  EXPECT_FALSE(
      IsNonBlocking(MultiprocessTestHelper::client_platform_handle.get()))
      << "DISREGARD: Expected failure #2 in child process";
}

}  // namespace
}  // namespace test
}  // namespace mojo
