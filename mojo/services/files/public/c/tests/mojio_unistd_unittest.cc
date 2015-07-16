// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Basic tests of things declared in mojio_unistd.h, as well as
// |mojio_creat()|/|mojio_open()| from mojio_fcntl.h. Note that more thorough
// tests are done more directly at a different level.

#include <errno.h>
#include <string.h>

#include "files/public/c/mojio_fcntl.h"
#include "files/public/c/mojio_sys_stat.h"
#include "files/public/c/mojio_unistd.h"
#include "files/public/c/tests/mojio_test_base.h"

namespace {

using MojioUnistdTest = mojio::test::MojioTestBase;

TEST_F(MojioUnistdTest, CreatWriteOpenCloseReadClose) {
  const char kTestFileName[] = "test_file";
  const char kTestData[] = "Hello mojio!";

  errno = 12345;
  int write_fd = mojio_creat(kTestFileName, MOJIO_S_IRWXU);
  int errno_value = errno;  // |ASSERT_EQ()| might conceivably change errno.
  ASSERT_EQ(0, write_fd);   // FDs are allocated starting from 0.
  EXPECT_EQ(12345, errno_value);  // errno should be untouched.

  errno = 12345;
  mojio_ssize_t bytes_written =
      mojio_write(write_fd, kTestData, sizeof(kTestData));
  errno_value = errno;
  EXPECT_EQ(static_cast<mojio_ssize_t>(sizeof(kTestData)), bytes_written);
  EXPECT_EQ(12345, errno_value);

  errno = 12345;
  int read_fd = mojio_open(kTestFileName, MOJIO_O_RDONLY);
  errno_value = errno;
  ASSERT_EQ(1, read_fd);  // |write_fd| is still open, so we should get 1.
  EXPECT_EQ(12345, errno_value);

  errno = 12345;
  int result = mojio_close(write_fd);
  errno_value = errno;
  EXPECT_EQ(0, result);
  EXPECT_EQ(12345, errno_value);

  char buffer[100] = {};
  errno = 12345;
  mojio_ssize_t bytes_read = mojio_read(read_fd, buffer, sizeof(buffer));
  errno_value = errno;
  EXPECT_EQ(static_cast<mojio_ssize_t>(sizeof(kTestData)), bytes_read);
  EXPECT_EQ(12345, errno_value);
  EXPECT_EQ(0, memcmp(buffer, kTestData, sizeof(kTestData)));
  EXPECT_EQ('\0', buffer[sizeof(kTestData)]);

  errno = 12345;
  result = mojio_close(read_fd);
  errno_value = errno;
  EXPECT_EQ(0, result);
  EXPECT_EQ(12345, errno_value);
}

TEST_F(MojioUnistdTest, FtruncateLseek) {
  const char kTestData[] = "Hello mojio!";

  int fd = mojio_open("my_file", MOJIO_O_CREAT | MOJIO_O_RDWR, MOJIO_S_IRWXU);
  EXPECT_GE(fd, 0);

  mojio_ssize_t bytes_written = mojio_write(fd, kTestData, sizeof(kTestData));
  EXPECT_EQ(static_cast<mojio_ssize_t>(sizeof(kTestData)), bytes_written);

  errno = 12345;
  int result = mojio_ftruncate(fd, sizeof(kTestData) - 2);
  int errno_value = errno;
  EXPECT_EQ(0, result);
  EXPECT_EQ(12345, errno_value);

  errno = 12345;
  mojio_off_t offset = mojio_lseek(fd, -5, MOJIO_SEEK_END);
  errno_value = errno;
  EXPECT_EQ(static_cast<mojio_off_t>(sizeof(kTestData)) - 2 - 5, offset);
  EXPECT_EQ(12345, errno_value);

  char buffer[100] = {};
  errno = 12345;
  mojio_ssize_t bytes_read = mojio_read(fd, buffer, sizeof(buffer));
  errno_value = errno;
  EXPECT_EQ(5, bytes_read);
  EXPECT_EQ(12345, errno_value);
  EXPECT_EQ(0, memcmp(buffer, &kTestData[sizeof(kTestData) - 2 - 5], 5));
  EXPECT_EQ('\0', buffer[5]);

  EXPECT_EQ(0, mojio_close(fd));
}

TEST_F(MojioUnistdTest, Ebadf) {
  errno = 12345;
  int result = mojio_close(-1);
  int errno_value = errno;
  EXPECT_EQ(-1, result);
  EXPECT_EQ(EBADF, errno_value);

  errno = 12345;
  result = mojio_dup(-1);
  errno_value = errno;
  EXPECT_EQ(-1, result);
  EXPECT_EQ(EBADF, errno_value);

  errno = 12345;
  result = mojio_ftruncate(-1, 0);
  errno_value = errno;
  EXPECT_EQ(-1, result);
  EXPECT_EQ(EBADF, errno_value);

  errno = 12345;
  mojio_off_t offset = mojio_lseek(-1, 0, MOJIO_SEEK_SET);
  errno_value = errno;
  EXPECT_EQ(-1, offset);
  EXPECT_EQ(EBADF, errno_value);

  char buf[10] = {};
  errno = 12345;
  mojio_ssize_t size = mojio_read(-1, buf, sizeof(buf));
  errno_value = errno;
  EXPECT_EQ(-1, size);
  EXPECT_EQ(EBADF, errno_value);

  errno = 12345;
  size = mojio_write(-1, buf, sizeof(buf));
  errno_value = errno;
  EXPECT_EQ(-1, size);
  EXPECT_EQ(EBADF, errno_value);
}

// TODO(vtl): mojio_chdir(), mojio_dup().

}  // namespace
