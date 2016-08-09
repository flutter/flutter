// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/file_fd_impl.h"

#include <errno.h>

#include <string>

#include "files/c/mojio_sys_stat.h"
#include "files/c/mojio_unistd.h"
#include "files/c/tests/mock_errno_impl.h"
#include "files/c/tests/mojio_impl_test_base.h"
#include "files/c/tests/test_utils.h"
#include "files/interfaces/files.mojom-sync.h"
#include "files/interfaces/files.mojom.h"
#include "files/interfaces/types.mojom.h"
#include "mojo/public/cpp/bindings/synchronous_interface_ptr.h"

using mojo::SynchronousInterfacePtr;

namespace mojio {
namespace {

using FileFDImplTest = mojio::test::MojioImplTestBase;

const int kLastErrorSentinel = -12345;

TEST_F(FileFDImplTest, ConstructClose) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(
      &errno_impl,
      test::OpenFileAt(&dir, "my_file", mojo::files::kOpenFlagWrite |
                                            mojo::files::kOpenFlagCreate));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(ffdi.Close());
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
}

TEST_F(FileFDImplTest, Dup) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 1000);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(&errno_impl, test::OpenFileAt(&dir, "my_file",
                                                mojo::files::kOpenFlagRead));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  errno_impl.Reset(kLastErrorSentinel);
  std::unique_ptr<FDImpl> duped_ffdi = ffdi.Dup();
  EXPECT_TRUE(duped_ffdi);
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Seeking in one should change the position in the other.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(123, ffdi.Lseek(123, MOJIO_SEEK_SET));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(123, duped_ffdi->Lseek(0, MOJIO_SEEK_CUR));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // And vice versa.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(123 + 456, duped_ffdi->Lseek(456, MOJIO_SEEK_CUR));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(123 + 456, ffdi.Lseek(0, MOJIO_SEEK_CUR));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
}

TEST_F(FileFDImplTest, Ftruncate) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 1000);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(&errno_impl, test::OpenFileAt(&dir, "my_file",
                                                mojo::files::kOpenFlagWrite));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Truncate.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(ffdi.Ftruncate(123));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(123, test::GetFileSize(&dir, "my_file"));

  // Can also extend.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_TRUE(ffdi.Ftruncate(456));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  EXPECT_EQ(456, test::GetFileSize(&dir, "my_file"));

  // TODO(vtl): Check file position after |Ftruncate()|.

  // Invalid size.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_FALSE(ffdi.Ftruncate(-1));
  EXPECT_EQ(EINVAL, errno_impl.Get());
}

TEST_F(FileFDImplTest, Lseek) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 123);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(&errno_impl, test::OpenFileAt(&dir, "my_file",
                                                mojo::files::kOpenFlagWrite));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Seek and write in various places.

  // 5 from beginning.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(5, ffdi.Lseek(5, MOJIO_SEEK_SET));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Write a byte.
  errno_impl.Reset(kLastErrorSentinel);
  char c = 42;
  EXPECT_EQ(1, ffdi.Write(&c, 1));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // 42 from current.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(5 + 1 + 42, ffdi.Lseek(42, MOJIO_SEEK_CUR));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Write a byte.
  errno_impl.Reset(kLastErrorSentinel);
  c = 5;
  EXPECT_EQ(1, ffdi.Write(&c, 1));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // 5 before end.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(123 - 5, ffdi.Lseek(-5, MOJIO_SEEK_END));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Write a byte.
  errno_impl.Reset(kLastErrorSentinel);
  c = 0;
  EXPECT_EQ(1, ffdi.Write(&c, 1));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Now read everything and check.
  std::string expected_contents(123, '\0');
  for (size_t i = 0; i < 123; i++) {
    unsigned char c = static_cast<unsigned char>(i);
    expected_contents[i] = *reinterpret_cast<char*>(&c);
  }
  expected_contents[5] = 42;
  expected_contents[5 + 1 + 42] = 5;
  expected_contents[123 - 5] = 0;
  EXPECT_EQ(expected_contents, test::GetFileContents(&dir, "my_file"));
}

TEST_F(FileFDImplTest, Read) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file", 123);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(&errno_impl, test::OpenFileAt(&dir, "my_file",
                                                mojo::files::kOpenFlagRead));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Read a bit.
  errno_impl.Reset(kLastErrorSentinel);
  unsigned char buffer[1000] = {};
  EXPECT_EQ(23, ffdi.Read(buffer, 23));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  for (size_t i = 0; i < 23; i++)
    EXPECT_EQ(static_cast<unsigned char>(i), buffer[i]) << i;

  // Read too much.
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(100, ffdi.Read(buffer, sizeof(buffer)));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  for (size_t i = 0; i < 100; i++)
    EXPECT_EQ(static_cast<unsigned char>(23 + i), buffer[i]) << i;

  // Invalid |count| (must fit within |ssize_t|).
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(-1, ffdi.Read(buffer, static_cast<size_t>(-1)));
  EXPECT_EQ(EINVAL, errno_impl.Get());
}

TEST_F(FileFDImplTest, Write) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(
      &errno_impl,
      test::OpenFileAt(&dir, "my_file", mojo::files::kOpenFlagWrite |
                                            mojo::files::kOpenFlagCreate |
                                            mojo::files::kOpenFlagExclusive));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  // Write something.
  errno_impl.Reset(kLastErrorSentinel);
  const char kHello[] = {'h', 'e', 'l', 'l', 'o', ' '};
  EXPECT_EQ(static_cast<mojio_off_t>(sizeof(kHello)),
            ffdi.Write(kHello, sizeof(kHello)));

  // Write something else.
  const char kMojio[] = {'m', 'o', 'j', 'i', 'o'};
  EXPECT_EQ(static_cast<mojio_off_t>(sizeof(kMojio)),
            ffdi.Write(kMojio, sizeof(kMojio)));

  EXPECT_EQ(std::string("hello mojio"), test::GetFileContents(&dir, "my_file"));

  // Invalid |count| (must fit within |ssize_t|).
  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(-1, ffdi.Write(kHello, static_cast<size_t>(-1)));
  EXPECT_EQ(EINVAL, errno_impl.Get());
}

TEST_F(FileFDImplTest, Fstat) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::CreateTestFileAt(&dir, "my_file_0", 0);
  test::CreateTestFileAt(&dir, "my_file_1", 512);
  test::CreateTestFileAt(&dir, "my_file_2", 513);

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi0(&errno_impl, test::OpenFileAt(&dir, "my_file_0",
                                                 mojo::files::kOpenFlagRead));
  FileFDImpl ffdi1(&errno_impl, test::OpenFileAt(&dir, "my_file_1",
                                                 mojo::files::kOpenFlagRead));
  FileFDImpl ffdi2(&errno_impl, test::OpenFileAt(&dir, "my_file_2",
                                                 mojo::files::kOpenFlagRead));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  errno_impl.Reset(kLastErrorSentinel);
  struct mojio_stat buf0 = {};
  EXPECT_TRUE(ffdi0.Fstat(&buf0));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  // Note: Don't check the unfilled values. (Some of the checks may also be
  // fragile, depending on our level of support.)
  EXPECT_EQ(static_cast<mojio_mode_t>(MOJIO_S_IRWXU | MOJIO_S_IFREG),
            buf0.st_mode);       // Fragile.
  EXPECT_EQ(1u, buf0.st_nlink);  // Fragile.
  EXPECT_EQ(0, buf0.st_size);
  // Just check that |st_atim.tv_sec|, etc. are positive (a bit fragile).
  EXPECT_GT(buf0.st_atim.tv_sec, 0);
  EXPECT_GT(buf0.st_mtim.tv_sec, 0);
  EXPECT_GT(buf0.st_ctim.tv_sec, 0);
  EXPECT_EQ(1024, buf0.st_blksize);  // Fragile.
  EXPECT_EQ(0u, buf0.st_blocks);

  errno_impl.Reset(kLastErrorSentinel);
  struct mojio_stat buf1 = {};
  EXPECT_TRUE(ffdi1.Fstat(&buf1));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  // Only check the things that should be (interestingly) different.
  EXPECT_EQ(512, buf1.st_size);
  EXPECT_EQ(1u, buf1.st_blocks);

  errno_impl.Reset(kLastErrorSentinel);
  struct mojio_stat buf2 = {};
  EXPECT_TRUE(ffdi2.Fstat(&buf2));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.
  // Only check the things that should be (interestingly) different.
  EXPECT_EQ(513, buf2.st_size);
  EXPECT_EQ(2u, buf2.st_blocks);
}

TEST_F(FileFDImplTest, Efault) {
  auto dir = SynchronousInterfacePtr<mojo::files::Directory>::Create(
      directory().Pass());

  test::MockErrnoImpl errno_impl(kLastErrorSentinel);
  FileFDImpl ffdi(
      &errno_impl,
      test::OpenFileAt(&dir, "my_file", mojo::files::kOpenFlagRead |
                                            mojo::files::kOpenFlagWrite |
                                            mojo::files::kOpenFlagCreate |
                                            mojo::files::kOpenFlagExclusive));
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());  // No error.

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(-1, ffdi.Read(nullptr, 1));
  EXPECT_EQ(EFAULT, errno_impl.Get());

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_EQ(-1, ffdi.Write(nullptr, 1));
  EXPECT_EQ(EFAULT, errno_impl.Get());

  errno_impl.Reset(kLastErrorSentinel);
  EXPECT_FALSE(ffdi.Fstat(nullptr));
  EXPECT_EQ(EFAULT, errno_impl.Get());
}

}  // namespace
}  // namespace mojio
