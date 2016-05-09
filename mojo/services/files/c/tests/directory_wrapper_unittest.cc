// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/directory_wrapper.h"

#include <errno.h>

#include <memory>

#include "files/c/lib/fd_impl.h"
#include "files/c/mojio_fcntl.h"
#include "files/c/mojio_sys_stat.h"
#include "files/c/tests/mock_errno_impl.h"
#include "files/c/tests/mojio_impl_test_base.h"
#include "files/c/tests/test_utils.h"

using mojo::SynchronousInterfacePtr;

namespace mojio {
namespace {

using DirectoryWrapperTest = mojio::test::MojioImplTestBase;

const int kLastErrorSentinel = -12345;

// Note: |Open()|'s |mode| is currently basically ignored, so there's nothing to
// test yet. If this ever changes, we'll have to test it.

// TODO(vtl): Currently, the Files service/interface doesn't report
// complete/thorough errors, hence our errno checks are bit wacky.
TEST_F(DirectoryWrapperTest, OpenCreate) {
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, directory().Pass());

  // Opening a nonexistent file without MOJIO_O_CREAT should fail.
  EXPECT_FALSE(dw.Open("my_file", MOJIO_O_RDWR, MOJIO_S_IRWXU));
  EXPECT_EQ(EIO, errno_impl.Get());

  // Opening it with MOJIO_O_CREAT should work though.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(dw.Open("my_file", MOJIO_O_RDWR | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(0, test::GetFileSize(&dw.directory(), "my_file"));

  // And again.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // But not with MOJIO_O_EXCL.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_FALSE(dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_CREAT | MOJIO_O_EXCL,
                       MOJIO_S_IRWXU));
  EXPECT_EQ(EIO, errno_impl.Get());

  // Make a subdirectory.
  test::MakeDirAt(&dw.directory(), "my_dir");

  // Can't create a file of that name, even with MOJIO_O_CREAT.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_FALSE(
      dw.Open("my_dir", MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(EIO, errno_impl.Get());

  // Create a file in that subdirectory, let's say with MOJIO_O_EXCL.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(dw.Open("my_dir/foo",
                      MOJIO_O_WRONLY | MOJIO_O_CREAT | MOJIO_O_EXCL,
                      MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(0, test::GetFileSize(&dw.directory(), "my_dir/foo"));
}

TEST_F(DirectoryWrapperTest, OpenTruncate) {
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, directory().Pass());

  // Can't open a nonexistent file with only MOJIO_O_TRUNC.
  EXPECT_FALSE(
      dw.Open("nonexistent", MOJIO_O_WRONLY | MOJIO_O_TRUNC, MOJIO_S_IRWXU));
  EXPECT_EQ(EIO, errno_impl.Get());

  // But can with MOJIO_O_CREAT.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(dw.Open("to_create",
                      MOJIO_O_WRONLY | MOJIO_O_CREAT | MOJIO_O_TRUNC,
                      MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(0, test::GetFileSize(&dw.directory(), "to_create"));

  test::CreateTestFileAt(&dw.directory(), "my_file", 123);

  // Opening without MOJIO_O_TRUNC doesn't change the file size, with or without
  // MOJIO_O_CREAT.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  // But with MOJIO_O_TRUNC, it truncates (only test without MOJIO_O_CREAT).
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_TRUNC, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(0, test::GetFileSize(&dw.directory(), "my_file"));
}

TEST_F(DirectoryWrapperTest, OpenExisting) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 123);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, dir.PassInterfaceHandle());

  // Test various flags:
  EXPECT_TRUE(dw.Open("my_file", MOJIO_O_RDONLY, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(dw.Open("my_file", MOJIO_O_RDWR, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(dw.Open("my_file", MOJIO_O_WRONLY, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_APPEND, MOJIO_S_IRWXU));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dw.directory(), "my_file"));
}

// Note: This necessarily also involves the returned |FDImpl|'s |Write()|.
TEST_F(DirectoryWrapperTest, OpenAppend) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 123);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, dir.PassInterfaceHandle());

  std::unique_ptr<FDImpl> fdi =
      dw.Open("my_file", MOJIO_O_WRONLY | MOJIO_O_APPEND, MOJIO_S_IRWXU);
  EXPECT_TRUE(fdi);
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Write some stuff to it.
  errno_impl.Reset(kLastErrorSentinel);
  const char kWriteBuffer[45] = {'x', 'y', 'z'};
  EXPECT_EQ(45, fdi->Write(kWriteBuffer, sizeof(kWriteBuffer)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  EXPECT_EQ(123 + 45, test::GetFileSize(&dw.directory(), "my_file"));
}

TEST_F(DirectoryWrapperTest, OpenInvalidFlags) {
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, directory().Pass());

  // Invalid access mode (masked by MOJIO_O_ACCMODE).
  //
  // Note: POSIX "requires" that exactly one of MOJIO_O_RDONLY, MOJIO_O_RDWR, or
  // MOJIO_O_WRONLY be included. However, we follow Linux and let MOJIO_O_RDONLY
  // have value 0, so this can't be detected (POSIX allows this by saying that
  // missing one of these flags *may* result in EINVAL).
  //
  // However, the or of all three isn't valid, and we do give EINVAL for that.
  EXPECT_FALSE(dw.Open("my_file",
                       MOJIO_O_RDONLY | MOJIO_O_RDWR | MOJIO_O_WRONLY,
                       MOJIO_S_IRWXU));
  EXPECT_EQ(EINVAL, errno_impl.Get());
}

TEST_F(DirectoryWrapperTest, Efault) {
  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  DirectoryWrapper dw(&errno_impl, directory().Pass());

  EXPECT_FALSE(dw.Open(nullptr, MOJIO_O_WRONLY | MOJIO_O_CREAT, MOJIO_S_IRWXU));
  EXPECT_EQ(EFAULT, errno_impl.Get());

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_FALSE(dw.Chdir(nullptr));
  EXPECT_EQ(EFAULT, errno_impl.Get());
}

}  // namespace
}  // namespace mojio
