// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Basic tests of things declared in mojio_sys_stat.h. Note that more thorough
// tests are done more directly at a different level.

#include <errno.h>
#include <string.h>

#include "files/public/c/mojio_fcntl.h"
#include "files/public/c/mojio_sys_stat.h"
#include "files/public/c/mojio_unistd.h"
#include "files/public/c/tests/mojio_test_base.h"

namespace {

using MojioSysStatTest = mojio::test::MojioTestBase;

TEST_F(MojioSysStatTest, Fstat) {
  const char kTestData[511] = {};

  int fd = mojio_creat("my_file", MOJIO_S_IRWXU);
  EXPECT_GE(fd, 0);

  errno = 12345;
  struct mojio_stat buf = {};
  int result = mojio_fstat(fd, &buf);
  int errno_value = errno;
  EXPECT_EQ(0, result);
  EXPECT_EQ(12345, errno_value);
  // Note: Don't check the unfilled values. (Some of the checks may also be
  // fragile, depending on our level of support.)
  EXPECT_EQ(static_cast<mojio_mode_t>(MOJIO_S_IRWXU | MOJIO_S_IFREG),
            buf.st_mode);       // Fragile.
  EXPECT_EQ(1u, buf.st_nlink);  // Fragile.
  EXPECT_EQ(0, buf.st_size);
  // Just check that |st_atim.tv_sec|, etc. are positive (a bit fragile).
  EXPECT_GT(buf.st_atim.tv_sec, 0);
  EXPECT_GT(buf.st_mtim.tv_sec, 0);
  EXPECT_GT(buf.st_ctim.tv_sec, 0);
  EXPECT_EQ(1024, buf.st_blksize);  // Fragile.
  EXPECT_EQ(0u, buf.st_blocks);

  // We use various assumptions below about the amount that we write, so we may
  // as well assert this here.
  static_assert(sizeof(kTestData) == 511, "oops");
  EXPECT_EQ(511, mojio_write(fd, kTestData, 511));

  memset(&buf, 0, sizeof(buf));
  EXPECT_EQ(0, mojio_fstat(fd, &buf));
  EXPECT_EQ(511, buf.st_size);
  EXPECT_EQ(1u, buf.st_blocks);

  EXPECT_EQ(511, mojio_write(fd, kTestData, 511));

  memset(&buf, 0, sizeof(buf));
  EXPECT_EQ(0, mojio_fstat(fd, &buf));
  EXPECT_EQ(1022, buf.st_size);
  EXPECT_EQ(2u, buf.st_blocks);

  EXPECT_EQ(0, mojio_close(fd));
}

TEST_F(MojioSysStatTest, Ebadf) {
  struct mojio_stat buf = {};
  errno = 12345;
  int result = mojio_fstat(-1, &buf);
  int errno_value = errno;
  EXPECT_EQ(-1, result);
  EXPECT_EQ(EBADF, errno_value);
}

}  // namespace
